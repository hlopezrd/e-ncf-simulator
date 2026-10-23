module Api
  class AuthController < ApplicationController
    rate_limit to: 20, within: 1.minute, only: :create

    def create
      rnc = params[:rnc]
      usuario = params[:usuario]
      password = params[:password]

      auth_token = Auth::TokenService.authenticate(rnc: rnc, usuario: usuario, password: password)
      if auth_token
        response.set_cookie(
          "ecf_token",
          value: auth_token.token,
          httponly: true,
          secure: Rails.env.production?,
          same_site: :lax,
          expires: 1.hour.from_now,
          path: "/"
        )
        render json: {
          token: auth_token.token,
          expiresIn: 3600,
          tokenType: "Bearer"
        }
      else
        render json: { error: "Credenciales inválidas", request_id: request.request_id }, status: :unauthorized
      end
    end

    def destroy
      response.delete_cookie("ecf_token", path: "/")
      render json: { message: "Sesión cerrada" }
    end
  end
end
