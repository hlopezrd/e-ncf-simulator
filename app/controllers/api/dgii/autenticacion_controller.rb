require "base64"

module Api
  module Dgii
    class AutenticacionController < ApplicationController
      def semilla
        valor = SecureRandom.base64(32)
        fecha = Time.current
        AuthSeed.create!(valor: valor, fecha: fecha, expira: fecha + 5.minutes, usado: false)

        xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <SemillaModel>
            <valor>#{valor}</valor>
            <fecha>#{fecha.iso8601(7)}</fecha>
          </SemillaModel>
        XML

        render plain: xml.strip, content_type: "application/xml"
      end

      def validar_semilla
        xml = extract_xml
        if xml.blank?
          render json: { token: nil, error: "xml requerido" }, status: :bad_request
          return
        end

        result = Auth::SeedValidationService.call(xml)
        if result.success?
          render json: {
            token: result.token,
            expira: result.expira,
            expedido: result.expedido
          }
        else
          render json: { token: nil, error: result.error }, status: :unauthorized
        end
      end

      private

      def extract_xml
        file = params[:xml]
        return nil if file.blank?
        return file if file.is_a?(String)
        if file.respond_to?(:read)
          content = file.read
          file.rewind if file.respond_to?(:rewind)
          return content
        end
        if file.respond_to?(:tempfile)
          return File.read(file.tempfile.path)
        end
        file.to_s
      end
    end
  end
end
