module Api
  class CertificadosController < ApplicationController
    before_action :authenticate_request!

    def index
      return if performed?

      records = Certificate.order(created_at: :desc)
      render json: {
        data: records.map { |c| cert_json(c) },
        meta: { total: records.size }
      }
    end

    private

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
