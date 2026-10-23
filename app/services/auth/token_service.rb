module Auth
  class TokenService
    TEST_CREDENTIALS = {
      rnc: "101234567",
      usuario: "usuario-prueba",
      password: "password-prueba"
    }.freeze

    EXPIRES_IN = 3600

    def self.authenticate(rnc:, usuario:, password:)
      return nil unless rnc == TEST_CREDENTIALS[:rnc]
      return nil unless usuario == TEST_CREDENTIALS[:usuario]
      return nil unless password == TEST_CREDENTIALS[:password]

      issue_token(rnc: rnc)
    end

    def self.issue_token(rnc:)
      plaintext = "sim-token-#{SecureRandom.hex(16)}"
      record = AuthToken.create!(
        token_digest: Digest::SHA256.hexdigest(plaintext),
        rnc: rnc,
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
