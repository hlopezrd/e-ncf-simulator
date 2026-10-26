class Certificate < ApplicationRecord
  belongs_to :company, optional: true
  acts_as_paranoid
  has_paper_trail

  validates :rnc, presence: true
  validates :certificate_pem, presence: true
  validates :active, inclusion: { in: [ true, false ] }
  validates :thumbprint, uniqueness: true, allow_nil: true

  scope :active, -> { where(active: true) }

  before_validation :derive_metadata, if: :certificate_pem_changed?

  validate :certificate_must_be_valid

  def expired?
    return true if not_before.nil? || not_after.nil?
    now = Time.current
    now < not_before || now > not_after
  end

  def vigente?
    !expired?
  end

  private

  def certificate_must_be_valid
    return if certificate_pem.blank?
    OpenSSL::X509::Certificate.new(certificate_pem)
  rescue OpenSSL::X509::CertificateError, ArgumentError => e
    errors.add(:certificate_pem, "no es un certificado X.509 válido: #{e.message}")
  end

  def derive_metadata
    return if certificate_pem.blank?
    cert = OpenSSL::X509::Certificate.new(certificate_pem)
    self.subject = cert.subject.to_s
    self.issuer = cert.issuer.to_s
    self.serial = cert.serial.to_s
    self.not_before = cert.not_before
    self.not_after = cert.not_after
    self.thumbprint = Digest::SHA256.hexdigest(cert.to_der)
  rescue OpenSSL::X509::CertificateError, ArgumentError
    # Errores agregados por certificate_must_be_valid
  end
end
