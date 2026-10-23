class User < ApplicationRecord
  belongs_to :role
  has_many :auth_tokens, dependent: :destroy

  has_secure_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :rnc, presence: true
  validates :username, presence: true, uniqueness: { scope: :rnc }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }
end
