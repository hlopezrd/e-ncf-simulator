class AuthToken < ApplicationRecord
  attr_accessor :token

  validates :token_digest, presence: true, uniqueness: true
  validates :rnc, presence: true
  validates :expires_at, presence: true

  def expired?
    expires_at <= Time.current
  end

  def self.find_valid(plaintext_token)
    return nil if plaintext_token.blank?
    digest = Digest::SHA256.hexdigest(plaintext_token)
    record = find_by(token_digest: digest)
    return nil unless record
    return nil if record.expired?
    record
  end
end
