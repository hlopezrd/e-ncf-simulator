class ElectronicInvoice < ApplicationRecord
  has_many :validation_errors, dependent: :destroy

  ESTADOS = %w[En\ Proceso Aceptado Aceptado\ Condicional Rechazado].freeze

  validates :track_id, presence: true, uniqueness: true
  validates :rnc_emisor, presence: true
  validates :encf, presence: true
  validates :estado, presence: true, inclusion: { in: ESTADOS }
  validates :fecha_recepcion, presence: true
  validates :encf, uniqueness: { scope: :rnc_emisor, message: "ya existe para el RNC emisor" }

  def aceptado?
    estado == "Aceptado"
  end
end
