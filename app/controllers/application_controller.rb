class ApplicationController < ActionController::API
  before_action :set_request_context
  before_action :set_default_whodunnit
  before_action :limit_request_size
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

  def audit!(action, target, details = nil)
    AuditLog.create!(
      actor: current_auth_token&.rnc || "anonymous",
      action: action,
      target: target,
      details: details
    )
  rescue StandardError
    nil
  end

  MAX_REQUEST_BYTES = 5.megabytes

  def limit_request_size
    if request.content_length.to_i > MAX_REQUEST_BYTES
      render json: { error: "Payload too large", request_id: request.request_id }, status: :payload_too_large
    end
  end

  def set_request_context
    Thread.current[:request_id] = request.request_id
  end

  def set_default_whodunnit
    PaperTrail.request.whodunnit = "anonymous"
  end

  def clear_request_context
    Thread.current[:request_id] = nil
  end

  def authenticate_request!
    token = request.cookies["ecf_token"]
    if token.blank?
      header = request.headers["Authorization"]
      token = header&.split(" ")&.last
    end
    @current_auth_token = Auth::TokenService.find(token)
    PaperTrail.request.whodunnit = @current_auth_token&.rnc || "anonymous"
    unless @current_auth_token
      render json: { error: "Token inválido o expirado", request_id: request.request_id }, status: :unauthorized
    end
  end
end
