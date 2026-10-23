module Auth
  class TokenService
    EXPIRES_IN = 3600

    def self.authenticate(rnc:, usuario:, password:)
      user = User.find_by(rnc: rnc, username: usuario)
      return nil unless user
      return nil unless user.active?
      return nil unless user.authenticate(password)

      issue_token(user: user)
    end

    def self.issue_token(user:)
      plaintext = "sim-token-#{SecureRandom.hex(16)}"
      record = AuthToken.create!(
        token_digest: Digest::SHA256.hexdigest(plaintext),
        rnc: user.rnc,
        user: user,
        expires_at: Time.current + EXPIRES_IN.seconds
      )
      record.token = plaintext
      record
    end

    def self.valid?(token)
      AuthToken.find_valid(token).present?
    end

    def self.find(token)
      AuthToken.find_valid(token)
    end
  end
end
