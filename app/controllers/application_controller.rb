class ApplicationController < ActionController::API
  before_action :set_request_context
  after_action :clear_request_context

  rescue_from StandardError do |e|
    error_id = SecureRandom.uuid
    Rails.logger.error({
      error_id: error_id,
      request_id: request.request_id,
      exception: e.class.name,
      message: e.message,
      backtrace: e.backtrace&.first(15)
    }.to_json)
    render json: {
      error: "Error interno del servidor",
      error_id: error_id,
      request_id: request.request_id
    }, status: :internal_server_error
  end

  private

  attr_reader :current_auth_token

  def set_request_context
    Thread.current[:request_id] = request.request_id
  end

  def clear_request_context
    Thread.current[:request_id] = nil
  end

  def authenticate_request!
    header = request.headers["Authorization"]
    token = header&.split(" ")&.last
    @current_auth_token = Auth::TokenService.find(token)
    unless @current_auth_token
      render json: { error: "Token inválido o expirado", request_id: request.request_id }, status: :unauthorized
    end
  end
end
