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

      # Validacion de secuencia e-NCF autorizada (DGII).
      ncf_errors = []
      if ENV.fetch("NCF_SEQUENCE_VALIDATION_ENABLED") { "true" } == "true"
        rnc = validation.rnc_emisor
        encf = validation.encf
        tipo = validation.tipo_comprobante
        if rnc.present? && encf.present? && encf.to_s.start_with?("E") && encf.to_s.length >= 3
          encf_tipo = encf.to_s[1, 2]
          if tipo.present? && encf_tipo != tipo.to_s.rjust(2, "0")
            ncf_errors << { codigo: "E021", campo: "eNCF", mensaje: "El tipo del e-NCF no corresponde al tipo de comprobante", severidad: "ERROR" }
          end
          seq_num = encf.to_s[3..].to_i
          company = rnc.present? ? Company.find_by(rnc: rnc) : nil
          seq = NcfSequence.activas.find { |s| (company.present? ? s.company_id == company.id : s.rnc == rnc) && s.tipo == encf_tipo.to_i && s.vigente? && s.cubre?(seq_num) }
          unless seq
            ncf_errors << { codigo: "E020", campo: "eNCF", mensaje: "El e-NCF no pertenece a una secuencia autorizada para el RNC", severidad: "ERROR" }
          end

          # Verificar que el e-NCF no haya sido anulado.
          if NcfAnnulledRange.exists?(rnc: rnc, tipo: encf_tipo.to_i) && NcfAnnulledRange.where(rnc: rnc, tipo: encf_tipo.to_i).any? { |a| a.covers?(seq_num) }
            ncf_errors << { codigo: "E024", campo: "eNCF", mensaje: "El e-NCF fue anulado", severidad: "ERROR" }
          end

          # Verificar secuencialidad (sin saltos).
          unless ncf_errors.any? { |e| e[:codigo] == "E020" }
            accepted_seqs = NcfUsage.where(rnc: rnc).filter_map do |u|
              next unless u.encf.to_s.start_with?("E") && u.encf.to_s.length >= 3
              next unless u.encf.to_s[1, 2] == encf_tipo
              u.encf.to_s[3..].to_i
            end
            max_accepted = accepted_seqs.max || (seq.desde - 1)
            expected = max_accepted + 1
            # Saltar rangos anulados.
            loop do
              ann = NcfAnnulledRange.where(rnc: rnc, tipo: encf_tipo.to_i).find { |a| a.covers?(expected) }
              break unless ann
              expected = ann.hasta + 1
            end
            if seq_num > expected
              ncf_errors << { codigo: "E023", campo: "eNCF", mensaje: "El e-NCF no sigue la secuencia (no se permiten saltos)", severidad: "ERROR" }
            end
            if expected > seq.hasta
              ncf_errors << { codigo: "E025", campo: "eNCF", mensaje: "El rango de e-NCF está agotado", severidad: "ERROR" }
            end
          end
        end
      end

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
      # Solo se considera duplicado si ya fue aceptado (un rechazado puede reenviarse).
      duplicado = false
      if rnc_emisor.present? && encf.present? && ElectronicInvoice.exists?(rnc_emisor: rnc_emisor, encf: encf, estado: [ "Aceptado", "Aceptado Condicional" ])
        duplicado = true
      end

      track_id = SecureRandom.uuid
      fecha_recepcion = Time.current

      has_errors = validation.errors.any? || ncf_errors.any? || duplicado

      estado = if has_errors
                 "Rechazado"
      elsif validation.warnings.any?
                 "Aceptado Condicional"
      else
                 "Aceptado"
      end

      secuencia_utilizada = !has_errors

      company = rnc_emisor.present? ? Company.find_by(rnc: rnc_emisor) : nil
      invoice = ElectronicInvoice.create!(
        track_id: track_id,
        company: company,
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
      all_errors.concat(ncf_errors)
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

      unless has_errors
        if rnc_emisor.present? && encf.present?
          NcfUsage.create!(rnc: rnc_emisor, encf: encf, track_id: track_id)
        end
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
