require "openssl"
require "base64"

module Ecfs
  class CryptoService
    CERT_DIR = Rails.root.join("config", "certs")
    KEY_FILE = CERT_DIR.join("simulator.key")
    CERT_FILE = CERT_DIR.join("simulator.crt")

    def self.key
      @key ||= load_or_generate_key
    end

    def self.certificate
      @certificate ||= load_or_generate_certificate
    end

    def self.sign(xml)
      doc = Nokogiri::XML(xml, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET)
      # Remove any existing signature
      doc.xpath("//*[local-name()='Signature']").remove

      canonical = doc.canonicalize
      digest = Digest::SHA256.digest(canonical)
      digest_b64 = Base64.strict_encode64(digest)

      signed_info = <<~XML
        <SignedInfo xmlns="http://www.w3.org/2000/09/xmldsig#">
          <CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>
          <SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/>
          <Reference URI="">
            <DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/>
            <DigestValue>#{digest_b64}</DigestValue>
          </Reference>
        </SignedInfo>
      XML

      signed_info_doc = Nokogiri::XML(signed_info)
      signed_info_node = signed_info_doc.root
      canonical_signed_info = signed_info_node.canonicalize

      signature = key.sign(OpenSSL::Digest::SHA256.new, canonical_signed_info)
      signature_b64 = Base64.strict_encode64(signature)
      cert_b64 = Base64.strict_encode64(certificate.to_der)

      signature_node = Nokogiri::XML::Node.new("Signature", doc)
      signature_node.default_namespace = "http://www.w3.org/2000/09/xmldsig#"
      signature_node.add_child(Nokogiri::XML(signed_info).root)
      sig_value = Nokogiri::XML::Node.new("SignatureValue", doc)
      sig_value.content = signature_b64
      signature_node.add_child(sig_value)
      key_info = Nokogiri::XML::Node.new("KeyInfo", doc)
      x509_data = Nokogiri::XML::Node.new("X509Data", doc)
      x509_cert = Nokogiri::XML::Node.new("X509Certificate", doc)
      x509_cert.content = cert_b64
      x509_data.add_child(x509_cert)
      key_info.add_child(x509_data)
      signature_node.add_child(key_info)

      doc.root.add_child(signature_node)
      doc.to_xml
    end

    def self.verify(xml, registered_certificate: nil)
      if registered_certificate
        verify_with_registered(xml, registered_certificate)
      else
        verify_embedded(xml)
      end
    end

    def self.verify_embedded(xml)
      doc = Nokogiri::XML(xml, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET)
      signature_node = doc.xpath("//*[local-name()='Signature']").first
      return false unless signature_node

      signed_info_node = signature_node.xpath("./*[local-name()='SignedInfo']").first
      signature_value_node = signature_node.xpath("./*[local-name()='SignatureValue']").first
      x509_node = signature_node.xpath(".//*[local-name()='X509Certificate']").first
      return false unless signed_info_node && signature_value_node && x509_node

      cert = OpenSSL::X509::Certificate.new(Base64.decode64(x509_node.content.strip))
      now = Time.now
      return false if now < cert.not_before || now > cert.not_after

      signature = Base64.decode64(signature_value_node.content.strip)
      canonical_signed_info = signed_info_node.canonicalize

      valid_sig = cert.public_key.verify(OpenSSL::Digest::SHA256.new, signature, canonical_signed_info)
      return false unless valid_sig

      doc_copy = doc.dup
      doc_copy.xpath("//*[local-name()='Signature']").remove
      canonical_doc = doc_copy.canonicalize
      computed_digest = Base64.strict_encode64(Digest::SHA256.digest(canonical_doc))

      reference = signed_info_node.xpath("./*[local-name()='Reference']").first
      return false unless reference
      digest_value_node = reference.xpath("./*[local-name()='DigestValue']").first
      return false unless digest_value_node
      stored_digest = digest_value_node.content.strip

      computed_digest == stored_digest
    rescue StandardError
      false
    end

    def self.verify_with_registered(xml, registered_certificate)
      cert = OpenSSL::X509::Certificate.new(registered_certificate.certificate_pem)
      now = Time.now
      return false if now < cert.not_before || now > cert.not_after

      doc = Nokogiri::XML(xml, nil, nil, Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET)
      signature_node = doc.xpath("//*[local-name()='Signature']").first
      return false unless signature_node

      signed_info_node = signature_node.xpath("./*[local-name()='SignedInfo']").first
      signature_value_node = signature_node.xpath("./*[local-name()='SignatureValue']").first
      return false unless signed_info_node && signature_value_node

      signature = Base64.decode64(signature_value_node.content.strip)
      canonical_signed_info = signed_info_node.canonicalize

      valid_sig = cert.public_key.verify(OpenSSL::Digest::SHA256.new, signature, canonical_signed_info)
      return false unless valid_sig

      doc_copy = doc.dup
      doc_copy.xpath("//*[local-name()='Signature']").remove
      canonical_doc = doc_copy.canonicalize
      computed_digest = Base64.strict_encode64(Digest::SHA256.digest(canonical_doc))

      reference = signed_info_node.xpath("./*[local-name()='Reference']").first
      return false unless reference
      digest_value_node = reference.xpath("./*[local-name()='DigestValue']").first
      return false unless digest_value_node
      stored_digest = digest_value_node.content.strip

      computed_digest == stored_digest
    rescue StandardError
      false
    end

    private

    def self.load_or_generate_key
      CERT_DIR.mkdir unless CERT_DIR.exist?
      if KEY_FILE.exist?
        OpenSSL::PKey::RSA.new(File.read(KEY_FILE))
      else
        key = OpenSSL::PKey::RSA.new(2048)
        File.write(KEY_FILE, key.to_pem)
        key
      end
    end

    def self.load_or_generate_certificate
      CERT_DIR.mkdir unless CERT_DIR.exist?
      if CERT_FILE.exist?
        OpenSSL::X509::Certificate.new(File.read(CERT_FILE))
      else
        key = load_or_generate_key
        cert = OpenSSL::X509::Certificate.new
        cert.version = 2
        cert.serial = 1
        cert.subject = OpenSSL::X509::Name.parse("/CN=e-CF Simulator/O=e-CF Simulator")
        cert.issuer = cert.subject
        cert.public_key = key.public_key
        cert.not_before = Time.now
        cert.not_after = Time.now + 365 * 24 * 60 * 60
        cert.sign(key, OpenSSL::Digest::SHA256.new)
        File.write(CERT_FILE, cert.to_pem)
        cert
      end
    end
  end
end
