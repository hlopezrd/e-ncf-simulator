class SimulationRule < ApplicationRecord
  validates :name, presence: true
  validates :rule_type, presence: true
end
