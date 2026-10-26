require "base64"
require "jwt"

module Auth
  class SeedValidationService
    Result = Struct.new(:success?, :token, :expira, :expedido, :error, keyword_init: true)

    def self.call(xml)
      new(xml).call
    end

    def initialize(xml)
      @xml = xml
    end

    def call
      doc = Nokogiri::XML(@xml)
      valor_node = doc.xpath("//*[local-name()='valor']").first
      valor = valor_node&.text&.strip
      return failure("xml inválido: falta valor") if valor.blank?

      seed = AuthSeed.find_by(valor: valor)
      return failure("semilla no encontrada o ya usada") unless seed&.vigente?

      signature_node = doc.xpath("//*[local-name()='Signature']").first
      return failure("falta firma digital") unless signature_node

      x509_node = signature_node.xpath(".//*[local-name()='X509Certificate']").first
      return failure("falta certificado") unless x509_node

      registered_cert = nil
      begin
        embedded = OpenSSL::X509::Certificate.new(Base64.decode64(x509_node.content.strip))
        tp = Digest::SHA256.hexdigest(embedded.to_der)
        registered_cert = Certificate.active.find_by(thumbprint: tp)
      rescue StandardError
        registered_cert = nil
      end

      return failure("certificado no registrado") unless registered_cert
      return failure("certificado no vigente") if registered_cert.expired?

      unless Ecfs::CryptoService.verify(@xml, registered_certificate: registered_cert)
        return failure("firma digital inválida")
      end

      rnc = registered_cert.rnc
      now = Time.current
      exp = now + 1.hour
      claims = {
        "name" => rnc,
        "jti" => SecureRandom.uuid,
        "iat" => now.to_i,
        "nbf" => now.to_i,
        "exp" => exp.to_i,
        "iss" => "DGII.FE",
        "aud" => "USUARIOS.DGII.FE"
      }
      token = JWT.encode(claims, jwt_secret, "HS256")

      seed.marcar_usada!(rnc)

      Result.new(success?: true, token: token, expira: exp.utc.iso8601, expedido: now.utc.iso8601, error: nil)
    rescue StandardError => e
      failure("error: #{e.message}")
    end

    private

    def failure(msg)
      Result.new(success?: false, token: nil, expira: nil, expedido: nil, error: msg)
    end

    def jwt_secret
      ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }
    end
  end
end
