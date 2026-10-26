class NcfAnnulledRange < ApplicationRecord
  belongs_to :ncf_annulation, optional: true

  validates :rnc, presence: true
  validates :tipo, presence: true
  validates :desde, presence: true
  validates :hasta, presence: true

  def covers?(numero)
    numero.to_i.between?(desde, hasta)
  end
end
