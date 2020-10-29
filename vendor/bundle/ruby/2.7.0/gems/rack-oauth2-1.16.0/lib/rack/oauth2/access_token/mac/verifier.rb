module Rack
  module OAuth2
    class AccessToken
      class MAC
        class Verifier
          include AttrRequired, AttrOptional
          attr_required :algorithm

          class VerificationFailed < StandardError; end

          def initialize(attributes = {})
            (required_attributes + optional_attributes).each do |key|
              self.send :"#{key}=", attributes[key]
            end
            attr_missing!
          rescue AttrRequired::AttrMissing => e
            raise VerificationFailed.new("#{self.class.name.demodulize} Invalid: #{e.message}")
          end

          def verify!(expected)
            if expected == self.calculate
              :verified
            else
              raise VerificationFailed.new("#{self.class.name.demodulize} Invalid")
            end
          end

          private

          def hash_generator
            case algorithm.to_s
            when 'hmac-sha-1'
              OpenSSL::Digest::SHA1.new
            when 'hmac-sha-256'
              OpenSSL::Digest::SHA256.new
            else
              raise 'Unsupported Algorithm'
            end
          end
        end
      end
    end
  end
end
