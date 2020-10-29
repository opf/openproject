# frozen_string_literal: true

module Doorkeeper
  module Models
    module Revocable
      # Revokes the object (updates `:revoked_at` attribute setting its value
      # to the specific time).
      #
      # @param clock [Time] time object
      #
      def revoke(clock = Time)
        update_column(:revoked_at, clock.now.utc)
      end

      # Indicates whether the object has been revoked.
      #
      # @return [Boolean] true if revoked, false in other case
      #
      def revoked?
        !!(revoked_at && revoked_at <= Time.now.utc)
      end
    end
  end
end
