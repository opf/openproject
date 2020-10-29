module Rack
  module OAuth2
    class AccessToken
      class MAC
        class Sha256HexVerifier < Verifier
          attr_optional :raw_body

          def calculate
            return nil unless raw_body.present?
            
            OpenSSL::Digest::SHA256.new.digest(raw_body).unpack('H*').first
          end
        end
      end
    end
  end
end