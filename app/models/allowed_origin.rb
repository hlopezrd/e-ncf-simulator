class AllowedOrigin < ApplicationRecord
  validates :origin, presence: true, uniqueness: true
end
