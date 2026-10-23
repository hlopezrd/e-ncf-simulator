module Api
  class AuditoriaController < ApplicationController
    before_action :authenticate_request!

    def index
      return if performed?

      scope = AuditLog.order(created_at: :desc)
      scope = scope.where(actor: params[:actor]) if params[:actor].present?
      scope = scope.where(action: params[:action]) if params[:action].present?

      render json: {
        data: scope.map { |a| audit_json(a) },
        meta: { total: scope.size }
      }
    end

    private

    def audit_json(a)
      {
        id: a.id,
        actor: a.actor,
        action: a.action,
        target: a.target,
        details: a.details,
        createdAt: a.created_at.iso8601
      }
    end
  end
end
