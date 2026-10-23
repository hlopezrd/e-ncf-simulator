module Api
  class AuthController < ApplicationController
    def create
      rnc = params[:rnc]
      usuario = params[:usuario]
      password = params[:password]

      auth_token = Auth::TokenService.authenticate(rnc: rnc, usuario: usuario, password: password)
      if auth_token
        render json: {
          token: auth_token.token,
          expiresIn: 3600,
          tokenType: "Bearer"
        }
      else
        render json: { error: "Credenciales inválidas", request_id: request.request_id }, status: :unauthorized
      end
    end
  end
end
