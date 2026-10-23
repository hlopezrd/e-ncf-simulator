module Api
  class CertificadosController < ApplicationController
    before_action :authenticate_request!
  include RoleAuthorization
  before_action -> { require_roles(:admin) }, only: [ :create, :update, :destroy ]

    def index
      return if performed?
      records = Certificate.order(created_at: :desc)
      render json: {
        data: records.map { |c| cert_json(c) },
        meta: { total: records.size }
      }
    end

    def create
      return if performed?
      record = Certificate.new(cert_params)
      if record.save
        audit!("create_certificate", "Certificate##{record.id}", { rnc: record.rnc, thumbprint: record.thumbprint }.to_json)
        render json: cert_json(record), status: :created
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      return if performed?
      record = Certificate.find(params[:id])
      if record.update(cert_params)
        render json: cert_json(record)
      else
        render json: { errors: record.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { error: "No encontrado" }, status: :not_found
    end

    def destroy
      return if performed?
      record = Certificate.find(params[:id])
      audit!("destroy_certificate", "Certificate##{record.id}", { rnc: record.rnc }.to_json)
      record.destroy
      head :no_content
    rescue ActiveRecord::RecordNotFound
      render json: { error: "No encontrado" }, status: :not_found
    end

    private

    def cert_params
      params.permit(:rnc, :alias_name, :subject, :issuer, :serial, :not_before, :not_after, :thumbprint)
    end

    def cert_json(c)
      {
        id: c.id,
        rnc: c.rnc,
        alias: c.alias_name,
        subject: c.subject,
        issuer: c.issuer,
        serial: c.serial,
        notBefore: c.not_before&.iso8601,
        notAfter: c.not_after&.iso8601,
        thumbprint: c.thumbprint,
        createdAt: c.created_at.iso8601
      }
    end
  end
end
