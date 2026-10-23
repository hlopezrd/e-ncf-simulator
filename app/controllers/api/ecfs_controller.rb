module Api
  class EcfsController < ApplicationController
    before_action :authenticate_request!

    def index
      return if performed?

      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 20).to_i
      per_page = 100 if per_page > 100

      scope = ElectronicInvoice.order(fecha_recepcion: :desc)
      scope = scope.where(estado: params[:estado]) if params[:estado].present?
      scope = scope.where("rnc_emisor LIKE ?", "%#{params[:rnc]}%") if params[:rnc].present?

      total = scope.count
      records = scope.offset((page - 1) * per_page).limit(per_page)

      render json: {
        data: records.map { |r| ecf_json(r) },
        meta: { total: total, page: page, per_page: per_page }
      }
    end

    def show
      return if performed?

      record = ElectronicInvoice.find_by(track_id: params[:track_id])
      if record.nil?
        render json: { error: "TrackId no encontrado", request_id: request.request_id }, status: :not_found
      else
        render json: ecf_json(record).merge(xml: record.xml_content)
      end
    end

    private

    def ecf_json(record)
      {
        trackId: record.track_id,
        estado: record.estado,
        rncEmisor: record.rnc_emisor,
        eNCF: record.encf,
        tipoComprobante: record.tipo_comprobante,
        fechaEmision: record.fecha_emision&.iso8601,
        fechaRecepcion: record.fecha_recepcion.iso8601,
        errores: record.validation_errors.where(severidad: "ERROR").map(&:to_h),
        advertencias: record.validation_errors.where(severidad: "WARNING").map(&:to_h),
      }
    end
  end
end
