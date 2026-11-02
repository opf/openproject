# frozen_string_literal: true

module TestManagement
  # Encrypts CI access tokens (GitHub / GitLab personal or project access tokens) at rest.
  #
  # AES-256-GCM (authenticated) with a key derived from the instance's secret_key_base, so a
  # database dump alone does not reveal the tokens. Rotating secret_key_base makes stored tokens
  # unreadable (#decrypt returns nil, the connection shows "token unreadable – set it again").
  #
  # The Test Assistant (0014) encrypts the AI provider API key with the same scheme under its own
  # key salt (salt: TestManagement::Assistant::ProviderConfig::KEY_SALT).
  #
  # Deliberately not Redmine::Ciphering: that one stores plain text when no database cipher
  # key is configured, which is the default for many installations.
  module CiTokenCipher
    PREFIX = "tmv1:"
    KEY_SALT = "openproject test_management ci connection token"

    module_function

    def encrypt(plain, salt: KEY_SALT)
      return nil if plain.nil? || plain.to_s.empty?

      PREFIX + encryptor(salt).encrypt_and_sign(plain.to_s)
    end

    def decrypt(ciphertext, salt: KEY_SALT)
      return nil if ciphertext.blank? || !ciphertext.start_with?(PREFIX)

      encryptor(salt).decrypt_and_verify(ciphertext.delete_prefix(PREFIX))
    rescue ActiveSupport::MessageEncryptor::InvalidMessage, ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def encryptor(salt = KEY_SALT)
      key = Rails.application.key_generator.generate_key(salt, 32)
      ActiveSupport::MessageEncryptor.new(key, cipher: "aes-256-gcm", serializer: ActiveSupport::MessageEncryptor::NullSerializer)
    end
  end
end
