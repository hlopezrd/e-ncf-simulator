class SimulationRule < ApplicationRecord
  acts_as_paranoid
  has_paper_trail
  validates :name, presence: true
  validates :rule_type, presence: true
end
