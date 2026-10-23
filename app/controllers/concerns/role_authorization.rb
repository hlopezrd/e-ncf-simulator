module RoleAuthorization
  extend ActiveSupport::Concern

  class Forbidden < StandardError; end

  included do
    rescue_from Forbidden, with: :render_forbidden
  end

  private

  def require_roles(*roles)
    unless current_user && roles.map(&:to_s).include?(current_user.role.name)
      raise Forbidden
    end
  end

  def render_forbidden
    render json: { error: "Acceso denegado", request_id: request.request_id }, status: :forbidden
  end
end
