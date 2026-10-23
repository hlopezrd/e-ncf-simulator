module Api
  class UsuariosController < ApplicationController
    before_action :authenticate_request!

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

    private

    def user_json(u)
      {
        id: u.id,
        name: u.name,
        email: u.email,
        role: u.role.name,
        active: u.active,
        createdAt: u.created_at.iso8601
      }
    end
  end
end
