require "jwt"

module Api
  module Dgii
    class BaseController < ApplicationController
      before_action :authenticate_dgii!

      private

      attr_reader :current_rnc

      def authenticate_dgii!
        header = request.headers["Authorization"]
        token = header&.split(" ")&.last
        begin
          payload = JWT.decode(
            token,
            jwt_secret,
            true,
            algorithm: "HS256",
            iss: "DGII.FE",
            aud: "USUARIOS.DGII.FE",
            verify_iss: true,
            verify_aud: true
          )
          @current_rnc = payload.first["name"]
        rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::InvalidIssuerError, JWT::InvalidAudError, JWT::VerificationError
          render json: { error: "Token inválido o expirado" }, status: :unauthorized
        end
      end

      def jwt_secret
        ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }
      end
    end
  end
end
