module Api
  class EmpresasController < ApplicationController
    before_action :authenticate_request!
  include RoleAuthorization

    def index
      return if performed?

      rows = ElectronicInvoice.group(:rnc_emisor).select(
        "rnc_emisor, COUNT(*) AS total_ecf, MAX(fecha_recepcion) AS ultima_recepcion"
      )

      data = rows.map do |r|
        ultima = r.ultima_recepcion
        ultima = Time.zone.parse(ultima) if ultima.is_a?(String)

        {
          rnc: r.rnc_emisor,
          totalEcf: r.total_ecf,
          ultimaRecepcion: ultima&.iso8601
        }
      end

      render json: { data: data, meta: { total: data.size } }
    end
  end
end
