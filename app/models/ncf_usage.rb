class NcfUsage < ApplicationRecord
  validates :rnc, presence: true
  validates :encf, presence: true
  validates :track_id, presence: true
end
