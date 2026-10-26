class NcfSequence < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  validates :rnc, presence: true
  validates :tipo, presence: true
  validates :desde, presence: true
  validates :hasta, presence: true
  validates :fecha_vencimiento, presence: true
  validates :activa, inclusion: { in: [ true, false ] }

  scope :activas, -> { where(activa: true) }

  def vigente?
    activa && fecha_vencimiento >= Date.current
  end

  def cubre?(numero)
    numero.to_i.between?(desde, hasta)
  end
end
