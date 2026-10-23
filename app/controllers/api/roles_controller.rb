module Api
  class RolesController < ApplicationController
    before_action :authenticate_request!
    include RoleAuthorization
    before_action -> { require_roles(:admin) }

    def index
      return if performed?
      records = Role.order(:name)
      render json: { data: records.map { |r| { id: r.id, name: r.name, description: r.description } }, meta: { total: records.size } }
    end
  end
end
