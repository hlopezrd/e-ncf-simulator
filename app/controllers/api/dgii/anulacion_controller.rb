require "base64"

module Api
  module Dgii
    class AnulacionController < BaseController
      def create
        xml = extract_xml
        if xml.blank?
          render json: { rnc: nil, codigo: "1", nombre: "", mensajes: [ "xml requerido" ] }, status: :bad_request
          return
        end
        result = Ecfs::ReceiveAnnulationService.call(xml: xml)
        render json: result.payload, status: :ok
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
