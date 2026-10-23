class Certificate < ApplicationRecord
  acts_as_paranoid
  has_paper_trail
  validates :rnc, presence: true
  validates :thumbprint, uniqueness: true, allow_nil: true
end
