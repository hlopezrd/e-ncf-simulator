module Api
  class RolesController < ApplicationController
    before_action :authenticate_request!

    def index
      return if performed?
      records = Role.order(:name)
      render json: { data: records.map { |r| { id: r.id, name: r.name, description: r.description } }, meta: { total: records.size } }
    end

    def create
      return if performed?
      record = Role.new(role_params)
      if record.save
        audit!("create_role", "Role##{record.id}", { name: record.name }.to_json)
        render json: { id: record.id, name: record.name, description: record.description }, status: :created
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      return if performed?
      record = Role.find(params[:id])
      if record.update(role_params)
        render json: { id: record.id, name: record.name, description: record.description }
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "No encontrado" }, status: :not_found
    end

    def destroy
      return if performed?
      record = Role.find(params[:id])
      audit!("destroy_role", "Role##{record.id}", { name: record.name }.to_json)
      record.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render json: { error: "No encontrado" }, status: :not_found
    end

    private

    def role_params
      params.permit(:name, :description)
    end
  end
end
