require "base64"

module Api
  module Dgii
    class ResumenController < BaseController
      rate_limit to: 60, within: 1.minute, only: :create

      def create
        xml = extract_xml
        if xml.blank?
          render json: { codigo: 2, estado: "Rechazado", mensajes: [ { valor: "xml requerido", codigo: "X000" } ], encf: nil, secuenciaUtilizada: false }, status: :bad_request
          return
        end
        result = Ecfs::ReceiveSummaryService.call(xml: xml)
        audit!("dgii_resumen", "InvoiceSummary", result.payload.to_json)
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
