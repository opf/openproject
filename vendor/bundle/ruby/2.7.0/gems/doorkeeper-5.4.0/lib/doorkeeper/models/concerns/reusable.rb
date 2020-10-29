# frozen_string_literal: true

module Doorkeeper
  module Models
    module Reusable
      # Indicates whether the object is reusable (i.e. It is not expired and
      # has not crossed reuse_limit).
      #
      # @return [Boolean] true if can be reused and false in other case
      def reusable?
        return false if expired?
        return true unless expires_in

        threshold_limit = 100 - Doorkeeper.config.token_reuse_limit
        expires_in_seconds >= threshold_limit * expires_in / 100
      end
    end
  end
end
