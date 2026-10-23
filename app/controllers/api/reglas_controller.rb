module Api
  class ReglasController < ApplicationController
    before_action :authenticate_request!

    def index
      return if performed?

      records = SimulationRule.order(created_at: :desc)
      records = records.where(active: params[:active]) if params[:active].present?

      render json: {
        data: records.map { |r| rule_json(r) },
        meta: { total: records.size }
      }
    end

    private

    def rule_json(r)
      {
        id: r.id,
        name: r.name,
        description: r.description,
        ruleType: r.rule_type,
        active: r.active,
        value: r.value,
        createdAt: r.created_at.iso8601,
        updatedAt: r.updated_at.iso8601
      }
    end
  end
end
