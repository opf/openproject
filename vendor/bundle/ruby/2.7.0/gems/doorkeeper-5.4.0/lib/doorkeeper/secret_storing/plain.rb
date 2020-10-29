# frozen_string_literal: true

module Doorkeeper
  module SecretStoring
    ##
    # Plain text secret storing, which is the default
    # but also provides fallback lookup if
    # other secret storing mechanisms are enabled.
    class Plain < Base
      ##
      # Return the value to be stored by the database
      # @param plain_secret The plain secret input / generated
      def self.transform_secret(plain_secret)
        plain_secret
      end

      ##
      # Return the restored value from the database
      # @param resource The resource instance to act on
      # @param attribute The secret attribute to restore
      # as retrieved from the database.
      def self.restore_secret(resource, attribute)
        resource.public_send(attribute)
      end

      ##
      # Plain values obviously allow restoring
      def self.allows_restoring_secrets?
        true
      end
    end
  end
end
