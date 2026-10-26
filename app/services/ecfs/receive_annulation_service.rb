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

      # Parsear detalle de anulación.
      parsed = parse_detail(doc)

      if rnc_emisor.present? && errors.empty?
        # Validar que los rangos pertenezcan a secuencias autorizadas del RNC
        # y que no incluyan e-NCF ya consumidos.
        parsed.each do |line|
          seqs = line[:rangos]
          seqs.each do |r|
            desde = r[:desde].to_s[3..].to_i
            hasta = r[:hasta].to_s[3..].to_i
            tipo = line[:tipo].to_i
            # rango autorizado?
            authorized = NcfSequence.where(rnc: rnc_emisor, tipo: tipo).any? { |s| s.cubre?(desde) && s.cubre?(hasta) }
            unless authorized
              errors << { codigo: "E020", campo: "rango", mensaje: "El rango #{r[:desde]}..#{r[:hasta]} no pertenece a una secuencia autorizada", severidad: "ERROR" }
            end
            # no consumidos?
            if NcfUsage.where(rnc: rnc_emisor).any? { |u| u.encf.to_s[1, 2].to_i == tipo && u.encf.to_s[3..].to_i.between?(desde, hasta) }
              errors << { codigo: "E026", campo: "rango", mensaje: "El rango incluye e-NCF ya utilizados, no se puede anular", severidad: "ERROR" }
            end
          end
        end
      end

      if errors.empty?
        annulation = NcfAnnulation.create!(
          rnc_emisor: rnc_emisor,
          cantidad_anulados: parsed.sum { |l| l[:cantidad].to_i },
          fecha_hora_anulacion: nil,
          xml_content: @xml
        )
        # Registrar rangos anulados y marcar secuencias totalmente anuladas.
        parsed.each do |line|
          line[:rangos].each do |r|
            desde = r[:desde].to_s[3..].to_i
            hasta = r[:hasta].to_s[3..].to_i
            NcfAnnulledRange.create!(
              rnc: rnc_emisor,
              tipo: line[:tipo].to_i,
              desde: desde,
              hasta: hasta,
              ncf_annulation: annulation
            )
            NcfSequence.where(rnc: rnc_emisor, tipo: line[:tipo].to_i).each do |s|
              if s.desde == desde && s.hasta == hasta
                s.update!(anulada: true, activa: false)
              end
            end
          end
        end
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

    def parse_detail(doc)
      lines = []
      doc.xpath("//*[local-name()='Anulacion']").each do |anul|
        tipo = text_of_node(anul, "TipoeCF")
        cantidad = text_of_node(anul, "CantidadeNCFAnulados")
        rangos = []
        anul.xpath(".//*[local-name()='Secuencias']").each do |sec|
          desde = text_of_node(sec, "SecuenciaeNCFDesde")
          hasta = text_of_node(sec, "SecuenciaeNCFHasta")
          rangos << { desde: desde, hasta: hasta }
        end
        lines << { tipo: tipo, cantidad: cantidad, rangos: rangos }
      end
      lines
    end

    def text_of_node(node, name)
      n = node.xpath(".//*[local-name()='#{name}']").first
      n&.text&.strip
    end
  end
end
