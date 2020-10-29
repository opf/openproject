module OpenProject
  class Token
    class Extractor
      class Error < StandardError; end
      class KeyError < Error; end
      class DecryptionError < Error; end

      attr_accessor :key

      def initialize(key)
        @key = key
      end

      def read(data)
        unless key.public?
          raise KeyError, "Provided key is not a public key."
        end

        json_data = Base64.decode64(data.chomp)

        begin
          encryption_data = JSON.parse(json_data)
        rescue JSON::ParserError
          raise DecryptionError, "Encryption data is invalid JSON."
        end

        unless %w(data key iv).all? { |key| encryption_data[key] }
          raise DecryptionError, "Required field missing from encryption data."
        end

        encrypted_data  = Base64.decode64(encryption_data["data"])
        encrypted_key   = Base64.decode64(encryption_data["key"])
        aes_iv          = Base64.decode64(encryption_data["iv"])

        begin
          # Decrypt the AES key using asymmetric RSA encryption.
          aes_key = self.key.public_decrypt(encrypted_key)
        rescue OpenSSL::PKey::RSAError
          raise DecryptionError, "AES encryption key could not be decrypted."
        end

        # Decrypt the data using symmetric AES encryption.
        cipher = OpenSSL::Cipher::AES128.new(:CBC)
        cipher.decrypt

        begin
          cipher.key  = aes_key
        rescue OpenSSL::Cipher::CipherError
          raise DecryptionError, "AES encryption key is invalid."
        end

        begin
          cipher.iv   = aes_iv
        rescue OpenSSL::Cipher::CipherError
          raise DecryptionError, "AES IV is invalid."
        end

        begin
          data = cipher.update(encrypted_data) + cipher.final
        rescue OpenSSL::Cipher::CipherError
          raise DecryptionError, "Data could not be decrypted."
        end

        data
      end
    end
  end
end
