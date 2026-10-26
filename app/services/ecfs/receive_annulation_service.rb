require "base64"

module Ecfs
  class ReceiveAnnulationService
    Result = Struct.new(:success?, :payload, :errors, keyword_init: true)

    def self.call(xml:)
      new(xml: xml).call
    end

    def initialize(xml:)
      @xml = xml
    end

    def call
      errors = []
      errors.concat(Ecfs::XsdValidation.validate(@xml, "ANECF-v1.0.xsd"))

      doc = Nokogiri::XML(@xml)
      rnc_emisor = text_of(doc, "RncEmisor")
      cantidad = text_of(doc, "CantidadeNCFAnulados")
      fecha_hora = text_of(doc, "FechaHoraAnulacioneNCF")

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

      if errors.empty?
        NcfAnnulation.create!(
          rnc_emisor: rnc_emisor,
          cantidad_anulados: cantidad.to_i,
          fecha_hora_anulacion: nil,
          xml_content: @xml
        )
      end

      payload = {
        rnc: rnc_emisor,
        codigo: errors.empty? ? "0" : "1",
        nombre: "",
        mensajes: errors.map { |e| e[:mensaje] }
      }

      Result.new(success?: errors.empty?, payload: payload, errors: errors)
    rescue StandardError => e
      Result.new(success?: false, payload: { rnc: nil, codigo: "1", nombre: "", mensajes: [ e.message ] }, errors: [ { codigo: "X000", campo: "xml", mensaje: e.message, severidad: "ERROR" } ])
    end

    private

    def text_of(doc, name)
      node = doc.xpath("//*[local-name()='#{name}']").first
      node&.text&.strip
    end
  end
end
