class AuditLog < ApplicationRecord
  acts_as_paranoid
  has_paper_trail
  validates :actor, presence: true
  validates :action, presence: true
end
