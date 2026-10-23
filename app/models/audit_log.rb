class AuditLog < ApplicationRecord
  validates :actor, presence: true
  validates :action, presence: true
end
