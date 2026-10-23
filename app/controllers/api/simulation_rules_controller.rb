module Api
  class SimulationRulesController < ApplicationController
    before_action :authenticate_request!

    def index
      return if performed?
      records = SimulationRule.order(created_at: :desc)
      render json: { data: records.map { |r| rule_json(r) }, meta: { total: records.size } }
    end

    def create
      return if performed?
      record = SimulationRule.new(rule_params)
      if record.save
        audit!("create_simulation_rule", "SimulationRule##{record.id}", { name: record.name, rule_type: record.rule_type }.to_json)
        render json: rule_json(record), status: :created
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      return if performed?
      record = SimulationRule.find(params[:id])
      if record.update(rule_params)
        audit!("update_simulation_rule", "SimulationRule##{record.id}", rule_params.to_json)
        render json: rule_json(record)
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "No encontrado" }, status: :not_found
    end

    def destroy
      return if performed?
      record = SimulationRule.find(params[:id])
      audit!("destroy_simulation_rule", "SimulationRule##{record.id}", { name: record.name }.to_json)
      record.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render json: { error: "No encontrado" }, status: :not_found
    end

    private

    def rule_params
      params.permit(:name, :description, :rule_type, :active, :value)
    end

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
