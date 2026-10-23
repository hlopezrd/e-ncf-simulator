module Api
  class ValidacionesController < ApplicationController
    before_action :authenticate_request!

    def index
      return if performed?

      scope = ValidationError.joins(:electronic_invoice).order(created_at: :desc)
      scope = scope.where(severidad: params[:severidad]) if params[:severidad].present?

      render json: {
        data: scope.map { |v| val_json(v) },
        meta: { total: scope.count }
      }
    end

    private

    def val_json(v)
      {
        id: v.id,
        codigo: v.codigo,
        campo: v.campo,
        mensaje: v.mensaje,
        severidad: v.severidad,
        trackId: v.electronic_invoice.track_id,
        rncEmisor: v.electronic_invoice.rnc_emisor,
        eNCF: v.electronic_invoice.encf,
        createdAt: v.created_at.iso8601
      }
    end
  end
end
