require "base64"

module Ecfs
  class ReceiveSummaryService
    Result = Struct.new(:success?, :payload, :errors, keyword_init: true)

    def self.call(xml:)
      new(xml: xml).call
    end

    def initialize(xml:)
      @xml = xml
    end

    def call
      errors = []
      errors.concat(Ecfs::XsdValidation.validate(@xml, "RFCE-32-v1.0.xsd"))

      doc = Nokogiri::XML(@xml)
      rnc_emisor = text_of(doc, "RNCEmisor")
      encf = text_of(doc, "eNCF")
      monto_total = text_of(doc, "MontoTotal")
      total_itbis = text_of(doc, "TotalITBIS")
      codigo_seguridad = text_of(doc, "CodigoSeguridadeCF")

      registered_cert = nil
      if rnc_emisor.present?
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
        errors << { codigo: "E016", campo: "certificate", mensaje: "No hay certificado registrado para el RNC emisor", severidad: "ERROR" }
      elsif registered_cert.rnc != rnc_emisor
        errors << { codigo: "E018", campo: "certificate", mensaje: "El certificado no corresponde al RNC emisor", severidad: "ERROR" }
      elsif registered_cert.expired?
        errors << { codigo: "E017", campo: "certificate", mensaje: "El certificado registrado no está vigente", severidad: "ERROR" }
      else
        unless Ecfs::CryptoService.verify(@xml, registered_certificate: registered_cert)
          errors << { codigo: "E015", campo: "signature", mensaje: "La firma digital no es válida", severidad: "ERROR" }
        end
      end

      secuencia_utilizada = errors.empty?

      if errors.empty?
        InvoiceSummary.create!(
          rnc_emisor: rnc_emisor,
          encf: encf,
          codigo: 0,
          estado: "Aceptado",
          secuencia_utilizada: secuencia_utilizada,
          xml_content: @xml
        )
      end

      estado_text = errors.empty? ? "Aceptado" : "Rechazado"
      payload = {
        codigo: errors.empty? ? 0 : 2,
        estado: estado_text,
        mensajes: errors.map { |e| { valor: e[:mensaje], codigo: e[:codigo] } },
        encf: encf,
        secuenciaUtilizada: secuencia_utilizada
      }

      Result.new(success?: errors.empty?, payload: payload, errors: errors)
    rescue StandardError => e
      Result.new(success?: false, payload: { codigo: 2, estado: "Rechazado", mensajes: [ { valor: e.message, codigo: "X000" } ], encf: nil, secuenciaUtilizada: false }, errors: [ { codigo: "X000", campo: "xml", mensaje: e.message, severidad: "ERROR" } ])
    end

    private

    def text_of(doc, name)
      node = doc.xpath("//*[local-name()='#{name}']").first
      node&.text&.strip
    end
  end
end
