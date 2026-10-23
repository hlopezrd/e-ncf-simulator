module Api
  class TrackidsController < ApplicationController
    before_action :authenticate_request!

    def consulta
      return if performed?

      rnc = params[:rncemisor]
      encf = params[:encf]
      data = Ecfs::StatusQueryService.by_rnc_encf(rnc_emisor: rnc, encf: encf)
      render json: data.merge(request_id: request.request_id)
    end
  end
end
