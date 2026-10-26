module Api
  module Dgii
    class ConsultasController < BaseController
      def resultado
        track_id = params[:trackId]
        invoice = ElectronicInvoice.find_by(track_id: track_id)

        if invoice.nil?
          render json: {
            trackId: track_id,
            codigo: 0,
            estado: "No encontrado",
            rnc: nil,
            encf: nil,
            secuenciaUtilizada: false,
            fechaRecepcion: nil,
            mensajes: []
          }
          return
        end

        render json: {
          trackId: invoice.track_id,
          codigo: estado_a_codigo(invoice.estado),
          estado: invoice.estado == "Aceptado Condicional" ? "Aceptado Condicional" : invoice.estado,
          rnc: invoice.rnc_emisor,
          encf: invoice.encf,
          secuenciaUtilizada: invoice.secuencia_utilizada,
          fechaRecepcion: invoice.fecha_recepcion&.iso8601,
          mensajes: invoice.validation_errors.map { |e| { valor: e.mensaje, codigo: e.codigo } }
        }
      end

      def estado
        rnc_emisor = params[:rncEmisor]
        ncf = params[:ncfElectronico]
        invoice = ElectronicInvoice.where(rnc_emisor: rnc_emisor, encf: ncf).order(created_at: :desc).first

        if invoice.nil?
          render json: {
            codigo: 0,
            estado: "No encontrado",
            rncEmisor: rnc_emisor,
            ncfElectronico: ncf,
            montoTotal: nil,
            totalITBIS: nil,
            fechaEmision: nil,
            fechaFirma: nil,
            rncComprador: nil,
            codigoSeguridad: nil
          }
          return
        end

        render json: {
          codigo: estado_a_codigo(invoice.estado),
          estado: map_estado(invoice.estado),
          rncEmisor: invoice.rnc_emisor,
          ncfElectronico: invoice.encf,
          montoTotal: invoice.monto_total,
          totalITBIS: invoice.total_itbis,
          fechaEmision: invoice.fecha_emision&.to_s,
          fechaFirma: invoice.fecha_firma,
          rncComprador: invoice.rnc_comprador,
          codigoSeguridad: invoice.codigo_seguridad
        }
      end

      def track_ids
        rnc_emisor = params[:rncEmisor]
        encf = params[:encf]
        invoices = ElectronicInvoice.where(rnc_emisor: rnc_emisor, encf: encf).order(created_at: :desc)
        render json: invoices.map { |i|
          {
            trackId: i.track_id,
            estado: i.estado,
            fechaRecepcion: i.fecha_recepcion&.iso8601
          }
        }
      end

      private

      def estado_a_codigo(estado)
        case estado
        when "Aceptado" then 1
        when "Rechazado" then 2
        when "En Proceso" then 3
        when "Aceptado Condicional" then 4
        else 0
        end
      end

      def map_estado(estado)
        case estado
        when "Aceptado Condicional" then "Aceptado"
        else estado
        end
      end
    end
  end
end
