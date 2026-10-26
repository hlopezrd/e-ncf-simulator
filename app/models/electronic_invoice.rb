class ElectronicInvoice < ApplicationRecord
  acts_as_paranoid
  has_paper_trail
  has_many :validation_errors, dependent: :destroy

  ESTADOS = %w[En\ Proceso Aceptado Aceptado\ Condicional Rechazado].freeze

  validates :track_id, presence: true, uniqueness: true
  validates :rnc_emisor, presence: true
  validates :encf, presence: true
  validates :estado, presence: true, inclusion: { in: ESTADOS }
  validates :fecha_recepcion, presence: true
  # Unicidad de (rnc, encf) NO se valida a nivel de modelo: DGII permite
  # multiples TrackIds para el mismo e-NCF (intentos duplicados se rechazan).

  def aceptado?
    estado == "Aceptado"
  end
end
