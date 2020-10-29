# frozen_string_literal: true

module Doorkeeper
  module SecretStoring
    ##
    # Plain text secret storing, which is the default
    # but also provides fallback lookup if
    # other secret storing mechanisms are enabled.
    class Sha256Hash < Base
      ##
      # Return the value to be stored by the database
      # @param plain_secret The plain secret input / generated
      def self.transform_secret(plain_secret)
        ::Digest::SHA256.hexdigest plain_secret
      end

      ##
      # Determines whether this strategy supports restoring
      # secrets from the database. This allows detecting users
      # trying to use a non-restorable strategy with +reuse_access_tokens+.
      def self.allows_restoring_secrets?
        false
      end
    end
  end
end
