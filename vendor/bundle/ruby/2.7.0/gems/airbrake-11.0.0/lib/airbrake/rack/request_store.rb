# frozen_string_literal: true

module Airbrake
  module Rack
    # RequestStore is a thin (and limited) wrapper around *Thread.current* that
    # allows writing and reading thread-local variables under the +:airbrake+
    # key.
    # @api private
    # @since v8.1.3
    module RequestStore
      class << self
        # @return [Hash] a hash for all request-related data
        def store
          Thread.current[:airbrake] ||= {}
        end

        # @return [void]
        def []=(key, value)
          store[key] = value
        end

        # @return [Object]
        def [](key)
          store[key]
        end

        # @return [void]
        def clear
          Thread.current[:airbrake] = {}
        end
      end
    end
  end
end
