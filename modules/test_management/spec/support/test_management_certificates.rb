# frozen_string_literal: true

require "openssl"

# Throw-away CA and server certificates for the self-hosted Git specs (0015). Generated per run;
# nothing is read from disk.
module TestManagementCertificates
  module_function

  def key
    @key ||= OpenSSL::PKey::RSA.new(2048)
  end

  def certificate(subject:, issuer: nil, issuer_key: key, ca: false, not_after: 1.year.from_now)
    cert = OpenSSL::X509::Certificate.new
    cert.version = 2
    cert.serial = rand(1..(2**32))
    cert.subject = OpenSSL::X509::Name.parse(subject)
    cert.issuer = issuer ? issuer.subject : cert.subject
    cert.public_key = key.public_key
    cert.not_before = 1.day.ago
    cert.not_after = not_after
    extensions = OpenSSL::X509::ExtensionFactory.new
    extensions.subject_certificate = cert
    extensions.issuer_certificate = issuer || cert
    cert.add_extension(extensions.create_extension("basicConstraints", ca ? "CA:TRUE" : "CA:FALSE", true))
    cert.add_extension(extensions.create_extension("keyUsage", ca ? "keyCertSign,cRLSign" : "digitalSignature", true))
    cert.sign(issuer_key, OpenSSL::Digest.new("SHA256"))
    cert
  end

  def ca(name = "Example Internal Root CA", **)
    certificate(subject: "/CN=#{name}", ca: true, **)
  end

  def server(ca_certificate, host = "gitlab.internal.example")
    certificate(subject: "/CN=#{host}", issuer: ca_certificate)
  end
end
