require "base64"

module Api
  module Dgii
    class RecepcionController < BaseController
      def create
        xml = extract_xml
        if xml.blank?
          render json: { trackId: nil, error: "xml requerido", mensajes: [] }, status: :bad_request
          return
        end

        validation = Ecfs::ValidateXmlService.call(xml)
        if validation.rnc_emisor.present? && validation.rnc_emisor != current_rnc
          render json: {
            trackId: SecureRandom.uuid,
            error: "Usuario no delegado para el emisor",
            mensajes: [ { valor: "El usuario no está delegado para el RNC emisor", codigo: "E019" } ]
          }, status: :ok
          return
        end

        result = Ecfs::ReceiveService.call(xml: xml)
        render json: result.payload, status: result.status_code
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
