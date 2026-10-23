class Certificate < ApplicationRecord
  validates :rnc, presence: true
  validates :thumbprint, uniqueness: true, allow_nil: true
end
