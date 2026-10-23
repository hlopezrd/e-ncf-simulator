module Api
  class ConsultaEstadoController < ApplicationController
    before_action :authenticate_request!

    def show
      return if performed?

      data = Ecfs::StatusQueryService.by_track_id(params[:track_id])
      if data.nil?
        render json: { error: "TrackId no encontrado", request_id: request.request_id }, status: :not_found
      else
        render json: data.merge(request_id: request.request_id)
      end
    end
  end
end
