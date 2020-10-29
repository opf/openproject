require 'securerandom'
require 'bindata'
require 'aes_key_wrap'

module JSON
  class JWE
    class InvalidFormat < JWT::InvalidFormat; end
    class DecryptionFailed < JWT::VerificationFailed; end
    class UnexpectedAlgorithm < JWT::UnexpectedAlgorithm; end

    NUM_OF_SEGMENTS = 5

    include JOSE

    attr_accessor(
      :public_key_or_secret, :private_key_or_secret,
      :plain_text, :cipher_text, :iv, :auth_data,
      :content_encryption_key, :encryption_key, :mac_key
    )
    attr_writer :jwe_encrypted_key, :authentication_tag

    register_header_keys :enc, :epk, :zip, :apu, :apv
    alias_method :encryption_method, :enc

    def initialize(input = nil)
      self.plain_text = input.to_s
    end

    def encrypt!(public_key_or_secret)
      self.public_key_or_secret = with_jwk_support public_key_or_secret
      cipher.encrypt
      self.content_encryption_key = generate_content_encryption_key
      self.mac_key, self.encryption_key = derive_encryption_and_mac_keys
      cipher.key = encryption_key
      self.iv = cipher.random_iv # NOTE: 'iv' has to be set after 'key' for GCM
      self.auth_data = Base64.urlsafe_encode64 header.to_json, padding: false
      cipher.auth_data = auth_data if gcm?
      self.cipher_text = cipher.update(plain_text) + cipher.final
      self
    end

    def decrypt!(private_key_or_secret, algorithms = nil, encryption_methods = nil)
      raise UnexpectedAlgorithm.new('Unexpected alg header') unless algorithms.blank? || Array(algorithms).include?(alg)
      raise UnexpectedAlgorithm.new('Unexpected enc header') unless encryption_methods.blank? || Array(encryption_methods).include?(enc)
      self.private_key_or_secret = with_jwk_support private_key_or_secret
      cipher.decrypt
      self.content_encryption_key = decrypt_content_encryption_key
      self.mac_key, self.encryption_key = derive_encryption_and_mac_keys
      cipher.key = encryption_key
      cipher.iv = iv # NOTE: 'iv' has to be set after 'key' for GCM
      if gcm?
        # https://github.com/ruby/openssl/issues/63
        raise DecryptionFailed.new('Invalid authentication tag') if authentication_tag.length < 16
        cipher.auth_tag = authentication_tag
        cipher.auth_data = auth_data
      end
      self.plain_text = cipher.update(cipher_text) + cipher.final
      verify_cbc_authentication_tag! if cbc?
      self
    end

    def to_s
      [
        header.to_json,
        jwe_encrypted_key,
        iv,
        cipher_text,
        authentication_tag
      ].collect do |segment|
        Base64.urlsafe_encode64 segment.to_s, padding: false
      end.join('.')
    end

    def as_json(options = {})
      case options[:syntax]
      when :general
        {
          protected:  Base64.urlsafe_encode64(header.to_json, padding: false),
          recipients: [{
            encrypted_key: Base64.urlsafe_encode64(jwe_encrypted_key, padding: false)
          }],
          iv:         Base64.urlsafe_encode64(iv, padding: false),
          ciphertext: Base64.urlsafe_encode64(cipher_text, padding: false),
          tag:        Base64.urlsafe_encode64(authentication_tag, padding: false)
        }
      else
        {
          protected:     Base64.urlsafe_encode64(header.to_json, padding: false),
          encrypted_key: Base64.urlsafe_encode64(jwe_encrypted_key, padding: false),
          iv:            Base64.urlsafe_encode64(iv, padding: false),
          ciphertext:    Base64.urlsafe_encode64(cipher_text, padding: false),
          tag:           Base64.urlsafe_encode64(authentication_tag, padding: false)
        }
      end
    end

    private

    # common

    def gcm?
      [:A128GCM, :A256GCM].include? encryption_method&.to_sym
    end

    def cbc?
      [:'A128CBC-HS256', :'A256CBC-HS512'].include? encryption_method&.to_sym
    end

    def dir?
      :dir == alg&.to_sym
    end

    def cipher
      raise "#{cipher_name} isn't supported" unless OpenSSL::Cipher.ciphers.include?(cipher_name)
      @cipher ||= OpenSSL::Cipher.new cipher_name
    end

    def cipher_name
      case encryption_method&.to_sym
      when :A128GCM
        'aes-128-gcm'
      when :A256GCM
        'aes-256-gcm'
      when :'A128CBC-HS256'
        'aes-128-cbc'
      when :'A256CBC-HS512'
        'aes-256-cbc'
      else
        raise UnexpectedAlgorithm.new('Unknown Encryption Algorithm')
      end
    end

    def sha_size
      case encryption_method&.to_sym
      when :'A128CBC-HS256'
        256
      when :'A256CBC-HS512'
        512
      else
        raise UnexpectedAlgorithm.new('Unknown Hash Size')
      end
    end

    def sha_digest
      OpenSSL::Digest.new "SHA#{sha_size}"
    end

    def derive_encryption_and_mac_keys
      case
      when gcm?
        [:wont_be_used, content_encryption_key]
      when cbc?
        content_encryption_key.unpack(
          "a#{content_encryption_key.length / 2}" * 2
        )
      end
    end

    # encryption

    def jwe_encrypted_key
      @jwe_encrypted_key ||= case alg&.to_sym
      when :RSA1_5
        public_key_or_secret.public_encrypt content_encryption_key
      when :'RSA-OAEP'
        public_key_or_secret.public_encrypt content_encryption_key, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      when :A128KW, :A256KW
        AESKeyWrap.wrap content_encryption_key, public_key_or_secret
      when :dir
        ''
      when :'ECDH-ES'
        raise NotImplementedError.new('ECDH-ES not supported yet')
      when :'ECDH-ES+A128KW'
        raise NotImplementedError.new('ECDH-ES+A128KW not supported yet')
      when :'ECDH-ES+A256KW'
        raise NotImplementedError.new('ECDH-ES+A256KW not supported yet')
      else
        raise UnexpectedAlgorithm.new('Unknown Encryption Algorithm')
      end
    end

    def generate_content_encryption_key
      case
      when dir?
        public_key_or_secret
      when gcm?
        cipher.random_key
      when cbc?
        SecureRandom.random_bytes sha_size / 8
      end
    end

    def authentication_tag
      @authentication_tag ||= case
      when gcm?
        cipher.auth_tag
      when cbc?
        secured_input = [
          auth_data,
          iv,
          cipher_text,
          BinData::Uint64be.new(auth_data.length * 8).to_binary_s
        ].join
        OpenSSL::HMAC.digest(
          sha_digest, mac_key, secured_input
        )[0, sha_size / 2 / 8]
      end
    end

    # decryption

    def decrypt_content_encryption_key
      fake_content_encryption_key = generate_content_encryption_key # NOTE: do this always not to make timing difference
      case alg&.to_sym
      when :RSA1_5
        private_key_or_secret.private_decrypt jwe_encrypted_key
      when :'RSA-OAEP'
        private_key_or_secret.private_decrypt jwe_encrypted_key, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      when :A128KW, :A256KW
        AESKeyWrap.unwrap jwe_encrypted_key, private_key_or_secret
      when :dir
        private_key_or_secret
      when :'ECDH-ES'
        raise NotImplementedError.new('ECDH-ES not supported yet')
      when :'ECDH-ES+A128KW'
        raise NotImplementedError.new('ECDH-ES+A128KW not supported yet')
      when :'ECDH-ES+A256KW'
        raise NotImplementedError.new('ECDH-ES+A256KW not supported yet')
      else
        raise UnexpectedAlgorithm.new('Unknown Encryption Algorithm')
      end
    rescue OpenSSL::PKey::PKeyError
      fake_content_encryption_key
    end

    def verify_cbc_authentication_tag!
      secured_input = [
        auth_data,
        iv,
        cipher_text,
        BinData::Uint64be.new(auth_data.length * 8).to_binary_s
      ].join
      expected_authentication_tag = OpenSSL::HMAC.digest(
        sha_digest, mac_key, secured_input
      )[0, sha_size / 2 / 8]
      unless secure_compare(authentication_tag, expected_authentication_tag)
        raise DecryptionFailed.new('Invalid authentication tag')
      end
    end

    class << self
      def decode_compact_serialized(input, private_key_or_secret, algorithms = nil, encryption_methods = nil, _allow_blank_payload = false)
        unless input.count('.') + 1 == NUM_OF_SEGMENTS
          raise InvalidFormat.new("Invalid JWE Format. JWE should include #{NUM_OF_SEGMENTS} segments.")
        end
        jwe = new
        _header_json_, jwe.jwe_encrypted_key, jwe.iv, jwe.cipher_text, jwe.authentication_tag = input.split('.', NUM_OF_SEGMENTS).collect do |segment|
          begin
            Base64.urlsafe_decode64 segment
          rescue ArgumentError
            raise DecryptionFailed
          end
        end
        jwe.auth_data = input.split('.').first
        jwe.header = JSON.parse(_header_json_).with_indifferent_access
        unless private_key_or_secret == :skip_decryption
          jwe.decrypt! private_key_or_secret, algorithms, encryption_methods
        end
        jwe
      end

      def decode_json_serialized(input, private_key_or_secret, algorithms = nil, encryption_methods = nil, _allow_blank_payload = false)
        input = input.with_indifferent_access
        jwe_encrypted_key = if input[:recipients].present?
          input[:recipients].first[:encrypted_key]
        else
          input[:encrypted_key]
        end
        compact_serialized = [
          input[:protected],
          jwe_encrypted_key,
          input[:iv],
          input[:ciphertext],
          input[:tag]
        ].join('.')
        decode_compact_serialized compact_serialized, private_key_or_secret, algorithms, encryption_methods
      end
    end
  end
end
