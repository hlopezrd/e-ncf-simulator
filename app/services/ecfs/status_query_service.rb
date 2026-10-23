module Ecfs
  class StatusQueryService
    def self.by_track_id(track_id)
      invoice = ElectronicInvoice.find_by(track_id: track_id)
      return nil unless invoice
      {
        trackId: invoice.track_id,
        estado: invoice.estado,
        rncEmisor: invoice.rnc_emisor,
        eNCF: invoice.encf,
        fechaRecepcion: invoice.fecha_recepcion.iso8601,
        codigo: "0",
        mensaje: status_message(invoice.estado),
        errores: invoice.validation_errors.where(severidad: "ERROR").map(&:to_h),
        advertencias: invoice.validation_errors.where(severidad: "WARNING").map(&:to_h)
      }
    end

    def self.by_rnc_encf(rnc_emisor:, encf:)
      invoice = ElectronicInvoice.find_by(rnc_emisor: rnc_emisor, encf: encf)
      if invoice.nil?
        {
          trackId: nil,
          estado: "No Encontrado",
          mensaje: "No existe un e-CF recibido para el RNC y e-NCF indicados"
        }
      else
        {
          trackId: invoice.track_id,
          estado: invoice.estado,
          fechaRecepcion: invoice.fecha_recepcion.iso8601,
          rncEmisor: invoice.rnc_emisor,
          eNCF: invoice.encf
        }
      end
    end

    def self.status_message(estado)
      case estado
      when "Aceptado" then "e-CF validado correctamente"
      when "Aceptado Condicional" then "e-CF validado con advertencias"
      when "Rechazado" then "e-CF rechazado"
      when "En Proceso" then "e-CF en proceso"
      else "e-CF procesado"
      end
    end
  end
end
