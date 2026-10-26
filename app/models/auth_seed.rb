class AuthSeed < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  validates :valor, presence: true, uniqueness: true
  validates :fecha, presence: true
  validates :expira, presence: true
  validates :usado, inclusion: { in: [ true, false ] }

  def expirada?
    Time.current > expira
  end

  def vigente?
    !usado && !expirada?
  end

  def marcar_usada!(rnc)
    update!(usado: true, rnc: rnc)
  end
end
