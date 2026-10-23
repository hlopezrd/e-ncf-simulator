module Api
  class RecepcionController < ApplicationController
    before_action :authenticate_request!
  include RoleAuthorization
    rate_limit to: 60, within: 1.minute, only: :create

    def create
      return if performed?
      xml = params[:xml]
      result = Ecfs::ReceiveService.call(xml: xml)
      payload = result.payload.merge(request_id: request.request_id)
      if result.success?
        render json: payload, status: :ok
      else
        render json: payload, status: result.status_code
      end
    end
  end
end
