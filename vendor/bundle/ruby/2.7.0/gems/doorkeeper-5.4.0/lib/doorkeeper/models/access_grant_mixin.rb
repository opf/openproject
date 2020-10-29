# frozen_string_literal: true

module Doorkeeper
  module AccessGrantMixin
    extend ActiveSupport::Concern

    include OAuth::Helpers
    include Models::Expirable
    include Models::Revocable
    include Models::Accessible
    include Models::Orderable
    include Models::SecretStorable
    include Models::Scopes
    include Models::ResourceOwnerable

    # Never uses PKCE if PKCE migrations were not generated
    def uses_pkce?
      self.class.pkce_supported? && code_challenge.present?
    end

    module ClassMethods
      # Searches for Doorkeeper::AccessGrant record with the
      # specific token value.
      #
      # @param token [#to_s] token value (any object that responds to `#to_s`)
      #
      # @return [Doorkeeper::AccessGrant, nil]
      #   AccessGrant object or nil if there is no record with such token
      #
      def by_token(token)
        find_by_plaintext_token(:token, token)
      end

      # Revokes AccessGrant records that have not been revoked and associated
      # with the specific Application and Resource Owner.
      #
      # @param application_id [Integer]
      #   ID of the Application
      # @param resource_owner [ActiveRecord::Base, Integer]
      #   instance of the Resource Owner model or it's ID
      #
      def revoke_all_for(application_id, resource_owner, clock = Time)
        by_resource_owner(resource_owner)
          .where(
            application_id: application_id,
            revoked_at: nil,
          )
          .update_all(revoked_at: clock.now.utc)
      end

      # Implements PKCE code_challenge encoding without base64 padding as described in the spec.
      # https://tools.ietf.org/html/rfc7636#appendix-A
      #   Appendix A.  Notes on Implementing Base64url Encoding without Padding
      #
      #   This appendix describes how to implement a base64url-encoding
      #   function without padding, based upon the standard base64-encoding
      #   function that uses padding.
      #
      #       To be concrete, example C# code implementing these functions is shown
      #   below.  Similar code could be used in other languages.
      #
      #   static string base64urlencode(byte [] arg)
      #   {
      #       string s = Convert.ToBase64String(arg); // Regular base64 encoder
      #       s = s.Split('=')[0]; // Remove any trailing '='s
      #       s = s.Replace('+', '-'); // 62nd char of encoding
      #       s = s.Replace('/', '_'); // 63rd char of encoding
      #       return s;
      #   }
      #
      #   An example correspondence between unencoded and encoded values
      #   follows.  The octet sequence below encodes into the string below,
      #   which when decoded, reproduces the octet sequence.
      #
      #   3 236 255 224 193
      #
      #   A-z_4ME
      #
      # https://ruby-doc.org/stdlib-2.1.3/libdoc/base64/rdoc/Base64.html#method-i-urlsafe_encode64
      #
      # urlsafe_encode64(bin)
      # Returns the Base64-encoded version of bin. This method complies with
      # "Base 64 Encoding with URL and Filename Safe Alphabet" in RFC 4648.
      # The alphabet uses '-' instead of '+' and '_' instead of '/'.

      # @param code_verifier [#to_s] a one time use value (any object that responds to `#to_s`)
      #
      # @return [#to_s] An encoded code challenge based on the provided verifier
      # suitable for PKCE validation
      #
      def generate_code_challenge(code_verifier)
        padded_result = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier))
        padded_result.split("=")[0] # Remove any trailing '='
      end

      def pkce_supported?
        column_names.include?("code_challenge")
      end

      ##
      # Determines the secret storing transformer
      # Unless configured otherwise, uses the plain secret strategy
      #
      # @return [Doorkeeper::SecretStoring::Base]
      #
      def secret_strategy
        ::Doorkeeper.config.token_secret_strategy
      end

      ##
      # Determine the fallback storing strategy
      # Unless configured, there will be no fallback
      #
      # @return [Doorkeeper::SecretStoring::Base]
      #
      def fallback_secret_strategy
        ::Doorkeeper.config.token_secret_fallback_strategy
      end
    end
  end
end
