module Api
  class MeController < ApplicationController
    before_action :authenticate_request!

    def show
      return if performed?
      user = current_user
      if user.nil?
        render json: { error: "No autenticado" }, status: :unauthorized
      else
        render json: {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role.name,
          rnc: user.rnc
        }
      end
    end
  end
end
