class AuthToken < ApplicationRecord
  validates :token, presence: true, uniqueness: true
  validates :rnc, presence: true
  validates :expires_at, presence: true

  def expired?
    expires_at <= Time.current
  end

  def self.find_valid(token)
    record = find_by(token: token)
    return nil unless record
    return nil if record.expired?
    record
  end
end
