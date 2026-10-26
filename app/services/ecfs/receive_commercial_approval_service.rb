module Ecfs
  class ReceiveCommercialApprovalService
    Result = Struct.new(:success?, :payload, :errors, keyword_init: true)

    def self.call(xml:)
      new(xml: xml).call
    end

    def initialize(xml:)
      @xml = xml
    end

    def call
      errors = []
      errors.concat(Ecfs::XsdValidation.validate(@xml, "ACECF-v1.0.xsd"))

      doc = Nokogiri::XML(@xml)
      rnc_emisor = text_of(doc, "RNCEmisor")
      rnc_comprador = text_of(doc, "RNCComprador")
      encf = text_of(doc, "eNCF")
      estado_val = text_of(doc, "Estado")
      motivo = text_of(doc, "DetalleMotivoRechazo")
      fecha_hora = text_of(doc, "FechaHoraAprobacionComercial")

      # signature verification against registered cert of the signer (comprador)
      registered_cert = nil
      if rnc_comprador.present?
        sig_node = doc.xpath("//*[local-name()='Signature']").first
        if sig_node
          x509 = sig_node.xpath(".//*[local-name()='X509Certificate']").first
          if x509
            begin
              embedded = OpenSSL::X509::Certificate.new(Base64.decode64(x509.content.strip))
              tp = Digest::SHA256.hexdigest(embedded.to_der)
              registered_cert = Certificate.active.find_by(thumbprint: tp)
            rescue StandardError
              registered_cert = nil
            end
          end
        end
      end

      if registered_cert.nil?
        errors << { codigo: "E016", campo: "certificate", mensaje: "No hay certificado registrado para el RNC firmante", severidad: "ERROR" }
      elsif registered_cert.rnc != rnc_comprador
        errors << { codigo: "E018", campo: "certificate", mensaje: "El certificado no corresponde al RNC comprador", severidad: "ERROR" }
      elsif registered_cert.expired?
        errors << { codigo: "E017", campo: "certificate", mensaje: "El certificado registrado no está vigente", severidad: "ERROR" }
      else
        unless Ecfs::CryptoService.verify(@xml, registered_certificate: registered_cert)
          errors << { codigo: "E015", campo: "signature", mensaje: "La firma digital no es válida", severidad: "ERROR" }
        end
      end

      if errors.empty?
        CommercialApproval.create!(
          rnc_emisor: rnc_emisor,
          rnc_comprador: rnc_comprador,
          encf: encf,
          estado: estado_val.to_i,
          motivo_rechazo: motivo,
          fecha_hora_aprobacion: nil,
          xml_content: @xml
        )
        estado_code = estado_val == "1" ? "01" : "02"
        estado_text = estado_val == "1" ? "Aprobación Comercial Aprobada." : "Aprobacion Comercial Rechazada."
        mensaje = motivo.present? ? [ motivo ] : []
      else
        estado_code = "02"
        estado_text = "Aprobacion Comercial Rechazada."
        mensaje = errors.map { |e| e[:mensaje] }
      end

      payload = {
        codigo: estado_code,
        estado: estado_text,
        mensaje: mensaje
      }

      Result.new(success?: errors.empty?, payload: payload, errors: errors)
    rescue StandardError => e
      Result.new(success?: false, payload: { codigo: "02", estado: "Aprobacion Comercial Rechazada.", mensaje: [ e.message ] }, errors: [ { codigo: "X000", campo: "xml", mensaje: e.message, severidad: "ERROR" } ])
    end

    private

    def text_of(doc, name)
      node = doc.xpath("//*[local-name()='#{name}']").first
      node&.text&.strip
    end
  end
end
