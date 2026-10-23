module Ecfs
  class ReceiveService
    Result = Struct.new(:success?, :status_code, :payload, :errors, keyword_init: true)

    def self.call(xml:, token:)
      new(xml: xml, token: token).call
    end

    def initialize(xml:, token:)
      @xml = xml
      @token = token
    end

    def call
      auth_token = Auth::TokenService.find(@token)
      unless auth_token
        return Result.new(success?: false, status_code: 401, payload: { error: "Token inválido o expirado" }, errors: [])
      end

      validation = ValidateXmlService.call(@xml)

      if validation.errors.any?
        return Result.new(
          success?: false,
          status_code: 422,
          payload: {
            codigo: "VALIDATION_ERROR",
            mensaje: "El e-CF contiene errores de validación",
            errores: validation.errors
          },
          errors: validation.errors
        )
      end

      rnc_emisor = validation.rnc_emisor
      encf = validation.encf

      # Duplicate check
      if ElectronicInvoice.exists?(rnc_emisor: rnc_emisor, encf: encf)
        dup_error = { codigo: "E010", campo: "eNCF", mensaje: "El e-CF ya fue recibido (duplicado)", severidad: "ERROR" }
        return Result.new(
          success?: false,
          status_code: 422,
          payload: {
            codigo: "VALIDATION_ERROR",
            mensaje: "El e-CF contiene errores de validación",
            errores: [ dup_error ]
          },
          errors: [ dup_error ]
        )
      end

      track_id = SecureRandom.uuid
      fecha_recepcion = Time.current

      invoice = ElectronicInvoice.create!(
        track_id: track_id,
        rnc_emisor: rnc_emisor,
        encf: encf,
        tipo_comprobante: validation.tipo_comprobante,
        fecha_emision: parse_date(validation.fecha_emision),
        xml_content: @xml,
        estado: "En Proceso",
        fecha_recepcion: fecha_recepcion
      )

      validation.warnings.each do |w|
        invoice.validation_errors.create!(
          codigo: w[:codigo],
          campo: w[:campo],
          mensaje: w[:mensaje],
          severidad: w[:severidad]
        )
      end

      final_state = validation.warnings.any? ? "Aceptado Condicional" : "Aceptado"
      invoice.update!(estado: final_state)

      Result.new(
        success?: true,
        status_code: 200,
        payload: {
          trackId: track_id,
          codigo: "0",
          mensaje: "e-CF recibido correctamente",
          fechaRecepcion: fecha_recepcion.iso8601
        },
        errors: []
      )
    rescue ActiveRecord::RecordNotUnique
      dup_error = { codigo: "E010", campo: "eNCF", mensaje: "El e-CF ya fue recibido (duplicado)", severidad: "ERROR" }
      Result.new(
        success?: false,
        status_code: 422,
        payload: {
          codigo: "VALIDATION_ERROR",
          mensaje: "El e-CF contiene errores de validación",
          errores: [ dup_error ]
        },
        errors: [ dup_error ]
      )
    end

    private

    def parse_date(value)
      return nil if value.blank?
      Date.parse(value)
    rescue ArgumentError
      nil
    end
  end
end
