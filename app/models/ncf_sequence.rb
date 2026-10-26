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

  before_save :deactivate_siblings_if_activating

  def vigente?
    activa && !anulada && fecha_vencimiento >= Date.current
  end

  def cubre?(numero)
    numero.to_i.between?(desde, hasta)
  end

  def consumidos_count
    NcfUsage.where(rnc: rnc).count do |u|
      next false unless u.encf.to_s.start_with?("E") && u.encf.to_s.length >= 3
      next false unless u.encf.to_s[1, 2].to_i == tipo
      seq = u.encf.to_s[3..].to_i
      seq.between?(desde, hasta)
    end
  end

  def anulados_count
    NcfAnnulledRange.where(rnc: rnc, tipo: tipo).sum { |a| [ a.hasta, hasta ].min - [ a.desde, desde ].max + 1 }.clamp(0, hasta - desde + 1)
  end

  def disponibles_count
    (hasta - desde + 1) - consumidos_count - anulados_count
  end

  def estado
    return "Eliminada" if deleted_at.present?
    return "Anulada" if anulada
    return "Inactiva" unless activa
    return "Vencida" if fecha_vencimiento < Date.current
    "Vigente"
  end

  private

  def deactivate_siblings_if_activating
    return unless activa? && (activa_changed? || new_record?)
    NcfSequence.where(rnc: rnc, tipo: tipo, activa: true).where.not(id: id).update_all(activa: false)
  end
end
