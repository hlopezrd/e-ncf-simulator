module Ecfs
  class ReceiveService
    Result = Struct.new(:success?, :status_code, :payload, :errors, keyword_init: true)

    def self.call(xml:)
      new(xml: xml).call
    end

    def initialize(xml:)
      @xml = xml
    end

    def call
      validation = ValidateXmlService.call(@xml)

      rnc_emisor = validation.rnc_emisor
      encf = validation.encf
      tipo = validation.tipo_comprobante
      fecha_emision = validation.fecha_emision
      rnc_comprador = extract_rnc_comprador(validation.document)
      monto_total = extract_monto_total(validation.document)
      total_itbis = extract_total_itbis(validation.document)
      fecha_firma = extract_fecha_firma(validation.document)
      codigo_seguridad = extract_codigo_seguridad(@xml)

      # Duplicate check (informational; DGII may still assign a trackId).
      duplicado = false
      if rnc_emisor.present? && encf.present? && ElectronicInvoice.exists?(rnc_emisor: rnc_emisor, encf: encf)
        duplicado = true
      end

      track_id = SecureRandom.uuid
      fecha_recepcion = Time.current

      estado = if validation.errors.any? || duplicado
                 "Rechazado"
      elsif validation.warnings.any?
                 "Aceptado Condicional"
      else
                 "Aceptado"
      end

      secuencia_utilizada = !(validation.errors.any? || duplicado)

      invoice = ElectronicInvoice.create!(
        track_id: track_id,
        rnc_emisor: (rnc_emisor.presence || "000000000"),
        encf: (encf.presence || "E000000000000"),
        tipo_comprobante: tipo,
        fecha_emision: parse_date(fecha_emision),
        xml_content: @xml,
        estado: estado,
        fecha_recepcion: fecha_recepcion,
        rnc_comprador: rnc_comprador,
        monto_total: monto_total,
        total_itbis: total_itbis,
        fecha_firma: fecha_firma,
        codigo_seguridad: codigo_seguridad,
        secuencia_utilizada: secuencia_utilizada
      )

      # Store validation errors as messages.
      all_errors = validation.errors.dup
      if duplicado
        all_errors << { codigo: "E010", campo: "eNCF", mensaje: "El e-CF ya fue recibido (duplicado)", severidad: "ERROR" }
      end
      all_errors.each do |e|
        invoice.validation_errors.create!(
          codigo: e[:codigo],
          campo: e[:campo],
          mensaje: e[:mensaje],
          severidad: e[:severidad]
        )
      end

      validation.warnings.each do |w|
        invoice.validation_errors.create!(
          codigo: w[:codigo],
          campo: w[:campo],
          mensaje: w[:mensaje],
          severidad: w[:severidad]
        )
      end

      mensajes = all_errors.map { |e| { valor: e[:mensaje], codigo: e[:codigo].to_s.delete("E") } }
      # DGII uses numeric-ish codes; keep our codes as strings in `valor`? Use codigo as the error code.
      mensajes = all_errors.map { |e| { valor: e[:mensaje], codigo: e[:codigo] } }

      payload = {
        trackId: track_id,
        error: all_errors.any? ? "El e-CF contiene errores de validación" : "",
        mensajes: mensajes
      }

      Result.new(
        success?: all_errors.empty? && !duplicado,
        status_code: 200,
        payload: payload,
        errors: all_errors
      )
    rescue ActiveRecord::RecordInvalid => e
      # Fallback
      Result.new(
        success?: false,
        status_code: 422,
        payload: { trackId: nil, error: e.message, mensajes: [] },
        errors: []
      )
    end

    private

    def parse_date(value)
      return nil if value.blank?
      Date.parse(value)
    rescue ArgumentError
      nil
    end

    def extract_rnc_comprador(doc)
      return nil unless doc
      node = doc.xpath("//*[local-name()='RNCComprador']").first
      node&.text&.strip
    end

    def extract_monto_total(doc)
      return nil unless doc
      node = doc.xpath("//*[local-name()='MontoTotal']").first
      node&.text&.strip
    end

    def extract_total_itbis(doc)
      return nil unless doc
      node = doc.xpath("//*[local-name()='TotalITBIS']").first
      node&.text&.strip
    end

    def extract_fecha_firma(doc)
      return nil unless doc
      node = doc.xpath("//*[local-name()='FechaHoraFirma']").first
      node&.text&.strip
    end

    def extract_codigo_seguridad(xml)
      doc = Nokogiri::XML(xml)
      node = doc.xpath("//*[local-name()='SignatureValue']").first
      return nil unless node
      Digest::SHA256.hexdigest(node.content.strip)[0, 6]
    rescue StandardError
      nil
    end
  end
end
