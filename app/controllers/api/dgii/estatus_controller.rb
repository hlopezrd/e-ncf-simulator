module Api
  module Dgii
    class EstatusController < ApplicationController
      before_action :require_api_key

      SERVICES = %w[
        Autenticación Recepción Consulta\ Resultado Consulta\ Estado
        Consulta\ TrackIds Aprobación\ Comercial Anulación\ Rangos
        Recepción\ FC
      ].freeze

      def obtener_estatus
        ambiente = params[:ambiente] || "testecf"
        render json: SERVICES.map { |s|
          { servicio: s, estatus: "Disponible", ambiente: ambiente }
        }
      end

      def ventanas_mantenimiento
        render json: { ventanaMantenimientos: [] }
      end

      def verificar_estado
        render json: { estado: "Disponible" }
      end

      private

      def require_api_key
        if request.headers["Authorization"].blank?
          render json: { error: "API key requerida" }, status: :unauthorized
        end
      end
    end
  end
end
