module Api
  module Dgii
    class DirectorioController < BaseController
      rate_limit to: 60, within: 1.minute

      def obtener_por_rnc
        rnc = params[:rnc]
        cert = Certificate.active.find_by(rnc: rnc)
        if cert.nil?
          render json: nil, status: :not_found
          return
        end
        base = "#{request.base_url}/testecf"
        render json: {
          nombre: cert.alias_name || "Contribuyente #{rnc}",
          rnc: rnc,
          urlRecepcion: "#{base}/recepcion/api/facturaselectronicas",
          urlAceptacion: "#{base}/aprobacioncomercial/api/AprobacionComercial",
          urlOpcional: ""
        }
      end

      def listado
        rnc = params[:rnc]
        certs = rnc.present? ? Certificate.active.where(rnc: rnc) : Certificate.active
        base = "#{request.base_url}/testecf"
        render json: certs.map { |c|
          {
            nombre: c.alias_name || "Contribuyente #{c.rnc}",
            rnc: c.rnc,
            urlRecepcion: "#{base}/recepcion/api/facturaselectronicas",
            urlAceptacion: "#{base}/aprobacioncomercial/api/AprobacionComercial",
            urlOpcional: ""
          }
        }
      end
    end
  end
end
