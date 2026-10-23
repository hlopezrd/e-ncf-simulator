require "base64"

module Ecfs
  class ValidateXmlService
    def self.xsd_validation_enabled?
      ENV.fetch("XSD_VALIDATION_ENABLED") { "true" } == "true"
    end

    def self.signature_verification_enabled?
      ENV.fetch("SIGNATURE_VERIFICATION_ENABLED") { "true" } == "true"
    end

    Result = Struct.new(
      :valid?, :errors, :warnings, :document, :rnc_emisor, :encf,
      :tipo_comprobante, :fecha_emision, :totales_present?, keyword_init: true
    )

    def self.call(xml)
      new(xml).call
    end

    MAX_XML_BYTES = 1.megabyte

    def initialize(xml)
      @xml = xml
      @errors = []
      @warnings = []
    end

    def call
      if @xml.blank?
        @errors << error("E001", "xml", "El XML es obligatorio", "ERROR")
        return build_result(nil, nil, nil, nil, nil, nil, false)
      end

      if @xml.bytesize > MAX_XML_BYTES
        @errors << error("E011", "xml", "El XML excede el tamaño máximo permitido", "ERROR")
        return build_result(nil, nil, nil, nil, nil, nil, false)
      end

      begin
        doc = Nokogiri::XML(@xml) do |config|
          config.strict
          config.nonet
        end
      rescue Nokogiri::XML::SyntaxError => e
        @errors << error("E002", "xml", "El XML está mal formado: #{e.message}", "ERROR")
        return build_result(nil, nil, nil, nil, nil, nil, false)
      end

      if doc.errors.any?
        @errors << error("E002", "xml", "El XML está mal formado", "ERROR")
        return build_result(nil, nil, nil, nil, nil, nil, false)
      end

      unless doc.root
        @errors << error("E003", "root", "El nodo raíz es obligatorio", "ERROR")
        return build_result(doc, nil, nil, nil, nil, nil, false)
      end

      rnc = text_of(doc, %w[RNCEmisor RncEmisor rncEmisor])
      encf = text_of(doc, %w[eNCF ENCF encf])
      tipo = text_of(doc, %w[TipoeCF TipoECF tipoComprobante TipoComprobante])
      fecha = text_of(doc, %w[FechaEmision fechaEmision])
      totales_present = doc.xpath("//*[local-name()='Totales' or local-name()='Total' or local-name()='MontoTotal']").size.positive?

      if rnc.blank?
        @errors << error("E004", "rncEmisor", "El RNC emisor es obligatorio", "ERROR")
      end

      if encf.blank?
        @errors << error("E005", "eNCF", "El e-NCF es obligatorio", "ERROR")
      elsif !encf.to_s.start_with?("E")
        @errors << error("E006", "eNCF", "El e-NCF debe comenzar con E", "ERROR")
      end

      if tipo.blank?
        @errors << error("E007", "tipoComprobante", "El tipo de comprobante es obligatorio", "ERROR")
      end

      if fecha.blank?
        @errors << error("E008", "fechaEmision", "La fecha de emisión es obligatoria", "ERROR")
      end

      unless totales_present
        @errors << error("E009", "totales", "Los totales son obligatorios", "ERROR")
      end

      signature_node = doc.xpath("//*[local-name()='Signature']").first
      if signature_node.nil?
        @errors << error("E012", "signature", "La firma digital es obligatoria", "ERROR")
      else
        unless signature_node.xpath("./*[local-name()='SignatureValue']").any?
          @errors << error("E013", "signature", "Falta SignatureValue en la firma digital", "ERROR")
        end
        unless signature_node.xpath("./*[local-name()='SignedInfo']").any?
          @errors << error("E014", "signature", "Falta SignedInfo en la firma digital", "ERROR")
        end

        registered_cert = nil
        if rnc.present?
          registered_cert = Certificate.active.find_by(rnc: rnc)
        end

        if registered_cert.nil? && rnc.present?
          @errors << error("E016", "certificate", "No hay certificado registrado para el RNC emisor", "ERROR")
        end

        if registered_cert && (Time.current < registered_cert.not_before || Time.current > registered_cert.not_after)
          @errors << error("E017", "certificate", "El certificado registrado no está vigente", "ERROR")
        end

        # Comparar thumbprint del certificado embebido con el registrado.
        if registered_cert && signature_node
          embedded_node = signature_node.xpath(".//*[local-name()='X509Certificate']").first
          if embedded_node
            begin
              embedded_cert = OpenSSL::X509::Certificate.new(Base64.decode64(embedded_node.content.strip))
              embedded_tp = Digest::SHA256.hexdigest(embedded_cert.to_der)
              if embedded_tp != registered_cert.thumbprint
                @errors << error("E018", "certificate", "El certificado del XML no corresponde al registrado para el RNC", "ERROR")
              end
            rescue StandardError
              @errors << error("E018", "certificate", "El certificado del XML no corresponde al registrado para el RNC", "ERROR")
            end
          end
        end

        if self.class.signature_verification_enabled? && @errors.empty? && registered_cert
          unless Ecfs::CryptoService.verify(@xml, registered_certificate: registered_cert)
            @errors << error("E015", "signature", "La firma digital no es válida", "ERROR")
          end
        end
      end

      comprador = text_of(doc, %w[RNCComprador RncComprador rncComprador])
      if comprador.blank?
        @warnings << error("W001", "rncComprador", "Falta el RNC del comprador", "WARNING")
      end

      if self.class.xsd_validation_enabled?
        xsd_errors = validate_xsd(doc)
        @errors.concat(xsd_errors)
      end

      valid = @errors.empty?
      build_result(doc, rnc, encf, tipo, fecha, totales_present, valid)
    end

    private

    def text_of(doc, names)
      names.each do |name|
        node = doc.xpath("//*[local-name()='#{name}']").first
        return node.text.strip if node && node.text.present?
      end
      nil
    end

    def error(codigo, campo, mensaje, severidad)
      { codigo: codigo, campo: campo, mensaje: mensaje, severidad: severidad }
    end

    def validate_xsd(doc)
      tipo = text_of(doc, %w[TipoeCF])
      return [] if tipo.blank?

      schema_file = Rails.root.join("lib", "xsd", "e-CF-#{tipo}-v1.0.xsd")
      return [] unless File.exist?(schema_file)

      # Sanitize known DGII XSD quirks (e.g. leading spaces in type names).
      raw = File.read(schema_file)
      raw = raw.gsub(/(name|type)="\s+/, '\\1="')
      schema = Nokogiri::XML::Schema(raw)
      schema.validate(doc).map do |err|
        {
          codigo: "X001",
          campo: (err.path.presence || "xml"),
          mensaje: err.message.strip,
          severidad: "ERROR"
        }
      end
    rescue StandardError => e
      [ { codigo: "X000", campo: "xml", mensaje: "Error al cargar/validar XSD: #{e.message}", severidad: "ERROR" } ]
    end

    def build_result(doc, rnc, encf, tipo, fecha, totales_present, valid)
      Result.new(
        valid?: valid,
        errors: @errors,
        warnings: @warnings,
        document: doc,
        rnc_emisor: rnc,
        encf: encf,
        tipo_comprobante: tipo,
        fecha_emision: fecha,
        totales_present?: totales_present
      )
    end
  end
end
