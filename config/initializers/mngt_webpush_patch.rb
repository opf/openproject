# frozen_string_literal: true

# Patch webpush gem for OpenSSL 3.0+ / openssl gem 4.0 compatibility.
#
# OpenSSL 3.0 made EC key objects immutable (removed generate_key!, public_key=,
# private_key=). The openssl gem 4.0 then fully removed these deprecated methods.
# This patch rewrites the two affected classes using the new immutable-key API.
require "webpush"

module Webpush
  class VapidKey
    def initialize
      @curve = OpenSSL::PKey::EC.generate("prime256v1")
    end

    def self.from_keys(public_key, private_key)
      instance = allocate
      instance.instance_variable_set(:@curve, build_ec_key(public_key, private_key))
      instance
    end

    def public_key
      Base64.urlsafe_encode64(ec_public_point_bytes(@curve), padding: false)
    end

    def public_key_for_push_header
      Webpush.encode64(ec_public_point_bytes(@curve)).delete("=")
    end

    def private_key
      priv_bytes = ec_private_key_bytes(@curve)
      Base64.urlsafe_encode64(priv_bytes, padding: false)
    end

    def self.build_ec_key(pub_b64, priv_b64)
      group     = OpenSSL::PKey::EC::Group.new("prime256v1")
      priv_bn   = OpenSSL::BN.new(Base64.urlsafe_decode64(priv_b64), 2)
      pub_bytes = Base64.urlsafe_decode64(pub_b64)
      pub_point = OpenSSL::PKey::EC::Point.new(group, OpenSSL::BN.new(pub_bytes, 2))

      # Build ECPrivateKey DER (RFC 5915) — the only immutable-safe constructor
      der = OpenSSL::ASN1::Sequence.new([
        OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(1)),
        OpenSSL::ASN1::OctetString.new(priv_bn.to_s(2).rjust(32, "\x00")),
        OpenSSL::ASN1::ASN1Data.new(
          [OpenSSL::ASN1::ObjectId.new("prime256v1")],
          0, :CONTEXT_SPECIFIC
        ),
        OpenSSL::ASN1::ASN1Data.new(
          [OpenSSL::ASN1::BitString.new(pub_point.to_octet_string(:uncompressed))],
          1, :CONTEXT_SPECIFIC
        )
      ]).to_der

      OpenSSL::PKey::EC.new(der)
    end
    private_class_method :build_ec_key

    private

    # Extract uncompressed EC point bytes (65 bytes, 0x04 prefix) from a key.
    # Uses SubjectPublicKeyInfo DER since public_key accessor is removed in openssl 4.0.
    def ec_public_point_bytes(key)
      spki = OpenSSL::ASN1.decode(key.public_to_der)
      spki.value[1].value  # BitString value = raw EC point bytes
    end

    # Extract raw private key scalar bytes from ECPrivateKey DER.
    def ec_private_key_bytes(key)
      # private_to_der returns PKCS#8; ECPrivateKey is nested inside
      pkcs8 = OpenSSL::ASN1.decode(key.private_to_der)
      # PKCS#8: SEQUENCE { version, algorithm, OCTET STRING { ECPrivateKey } }
      ec_der = pkcs8.value[2].value
      ec_seq = OpenSSL::ASN1.decode(ec_der)
      # ECPrivateKey: SEQUENCE { version, OCTET STRING(privkey), [0]params, [1]pubkey }
      ec_seq.value[1].value.rjust(32, "\x00")
    end
  end

  module Encryption
    # Rewritten for openssl gem 4.0: generate_key is removed, public_key.to_bn is removed.
    def encrypt(message, p256dh, auth)
      assert_arguments(message, p256dh, auth)

      group_name = "prime256v1"
      salt = Random.new.bytes(16)

      server = OpenSSL::PKey::EC.generate(group_name)

      # Extract public point bytes from SubjectPublicKeyInfo DER
      spki = OpenSSL::ASN1.decode(server.public_to_der)
      server_pub_bytes = spki.value[1].value
      server_public_key_bn = OpenSSL::BN.new(server_pub_bytes, 2)

      group = OpenSSL::PKey::EC::Group.new(group_name)
      client_public_key_bn = OpenSSL::BN.new(Webpush.decode64(p256dh), 2)
      client_public_key = OpenSSL::PKey::EC::Point.new(group, client_public_key_bn)

      shared_secret = server.dh_compute_key(client_public_key)

      client_auth_token = Webpush.decode64(auth)

      info = "WebPush: info\0" + client_public_key_bn.to_s(2) + server_public_key_bn.to_s(2)
      content_encryption_key_info = "Content-Encoding: aes128gcm\0"
      nonce_info = "Content-Encoding: nonce\0"

      prk = HKDF.new(shared_secret, salt: client_auth_token, algorithm: "SHA256", info: info).next_bytes(32)

      content_encryption_key = HKDF.new(prk, salt: salt, info: content_encryption_key_info).next_bytes(16)

      nonce = HKDF.new(prk, salt: salt, info: nonce_info).next_bytes(12)

      ciphertext = encrypt_payload(message, content_encryption_key, nonce)

      serverkey16bn = convert16bit(server_public_key_bn)
      rs = ciphertext.bytesize
      raise ArgumentError, "encrypted payload is too big" if rs > 4096

      aes128gcmheader = "#{salt}" + [rs].pack("N*") + [serverkey16bn.bytesize].pack("C*") + serverkey16bn

      aes128gcmheader + ciphertext
    end
  end
end
