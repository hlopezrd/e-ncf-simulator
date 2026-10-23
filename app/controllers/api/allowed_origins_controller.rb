module Api
  class AllowedOriginsController < ApplicationController
    before_action :authenticate_request!

    def index
      return if performed?
      records = AllowedOrigin.order(created_at: :desc)
      render json: { data: records.map { |r| { id: r.id, origin: r.origin, createdAt: r.created_at.iso8601 } }, meta: { total: records.size } }
    end

    def create
      return if performed?
      record = AllowedOrigin.new(origin: params[:origin])
      if record.save
        render json: { id: record.id, origin: record.origin }, status: :created
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      return if performed?
      record = AllowedOrigin.find(params[:id])
      record.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render json: { error: "No encontrado" }, status: :not_found
    end
  end
end
