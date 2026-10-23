module Api
  class UsuariosController < ApplicationController
    before_action :authenticate_request!
  include RoleAuthorization
  before_action -> { require_roles(:admin) }

    def index
      return if performed?
      users = User.includes(:role).order(created_at: :desc)
      roles = Role.order(:name)

      render json: {
        users: users.map { |u| user_json(u) },
        roles: roles.map { |r| { id: r.id, name: r.name, description: r.description } },
        meta: { total_users: users.size, total_roles: roles.size }
      }
    end

    def create
      return if performed?
      role = Role.find(params[:role_id])
      record = User.new(user_params.merge(role: role))
      if record.save
        audit!("create_user", "User##{record.id}", { name: record.name, email: record.email, role: record.role.name }.to_json)
        render json: user_json(record), status: :created
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { errors: [ "Rol no encontrado" ] }, status: :unprocessable_entity
    end

    def update
      return if performed?
      record = User.find(params[:id])
      if params[:role_id].present?
        record.role = Role.find(params[:role_id])
      end
      if record.update(user_params.except(:role_id))
        render json: user_json(record)
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "No encontrado" }, status: :not_found
    end

    def destroy
      return if performed?
      record = User.find(params[:id])
      audit!("destroy_user", "User##{record.id}", { name: record.name, email: record.email }.to_json)
      record.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render json: { error: "No encontrado" }, status: :not_found
    end

    private

    def user_params
      params.permit(:name, :email, :rnc, :username, :active, :role_id, :password)
    end

    def user_json(u)
      {
        id: u.id,
        name: u.name,
        email: u.email,
        role: u.role.name,
        roleId: u.role_id,
        active: u.active,
        createdAt: u.created_at.iso8601
      }
    end
  end
end
