class AllowedOrigin < ApplicationRecord
  acts_as_paranoid
  has_paper_trail
  validates :origin, presence: true, uniqueness: true
end
