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
      pem = extract_pem
      record = Certificate.new(
        rnc: params[:rnc],
        alias_name: params[:alias_name],
        certificate_pem: pem,
        active: true
      )

      Certificate.transaction do
        Certificate.where(rnc: record.rnc, active: true).update_all(active: false)
        record.save!
      end

      audit!("create_certificate", "Certificate##{record.id}", { rnc: record.rnc, thumbprint: record.thumbprint }.to_json)
      render json: cert_json(record), status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    def update
      return if performed?
      record = Certificate.find(params[:id])
      if record.update(alias_name: params[:alias_name])
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

    def extract_pem
      file = params[:file]
      if file.present?
        content = file.respond_to?(:read) ? file.read : File.read(file.tempfile.path)
        file.rewind if file.respond_to?(:rewind)
        content
      else
        params[:certificate_pem]
      end
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
        active: c.active,
        createdAt: c.created_at.iso8601
      }
    end
  end
end
