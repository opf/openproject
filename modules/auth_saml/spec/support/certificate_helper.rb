module CertificateHelper
  module_function

  def private_key
    @private_key ||= OpenSSL::PKey::RSA.new(1024)
  end

  def valid_certificate
    @valid_certificate ||= begin
      name = OpenSSL::X509::Name.parse "/CN=valid-testing"
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1234

      cert.not_before = Time.now
      cert.not_after = Time.now + 606024364.251
      cert.public_key = private_key.public_key
      cert.subject = name
      cert.issuer = name
      cert.sign private_key, OpenSSL::Digest.new("SHA1")
    end
  end

  def expired_certificate
    @expired_certificate ||= begin
      name = OpenSSL::X509::Name.parse "/CN=expired-testing"
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1234

      cert.not_before = Time.now - 2.years
      cert.not_after = Time.now - 30.days
      cert.public_key = private_key.public_key
      cert.subject = name
      cert.issuer = name
      cert.sign private_key, OpenSSL::Digest.new("SHA1")
    end
  end

  def mismatched_certificate
    @mismatched_certificate ||= begin
      name = OpenSSL::X509::Name.parse "/CN=mismatched-testing"
      cert = OpenSSL::X509::Certificate.new
      cert.version = 2
      cert.serial = 1234

      key = OpenSSL::PKey::RSA.new(1024)
      cert.not_before = Time.now
      cert.not_after = Time.now + 606024364.251
      cert.public_key = key.public_key
      cert.subject = name
      cert.issuer = name
      cert.sign key, OpenSSL::Digest.new("SHA1")
    end
  end
end
