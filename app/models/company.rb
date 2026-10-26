class Company < ApplicationRecord
  self.table_name = "companies"

  acts_as_paranoid

  has_many :certificates, dependent: :destroy
  has_many :ncf_sequences, dependent: :destroy
  has_many :users, dependent: :nullify
  has_many :electronic_invoices, foreign_key: :company_id, dependent: :nullify

  validates :rnc, presence: true, uniqueness: true
  validates :rnc, format: { with: /\A\d{9}(\d{2})?\z/, message: "debe tener 9 u 11 dígitos" }

  def to_s
    razon_social.presence || rnc
  end
end