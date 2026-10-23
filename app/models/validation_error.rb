class ValidationError < ApplicationRecord
  belongs_to :electronic_invoice

  SEVERIDADES = %w[ERROR WARNING].freeze

  validates :codigo, presence: true
  validates :campo, presence: true
  validates :mensaje, presence: true
  validates :severidad, presence: true, inclusion: { in: SEVERIDADES }

  def to_h
    {
      codigo: codigo,
      campo: campo,
      mensaje: mensaje,
      severidad: severidad
    }
  end
end
