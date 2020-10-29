# frozen_string_literal: true

require 'dry/configurable/errors'

module Dry
  module Configurable
    # Common API for both classes and instances
    #
    # @api public
    module Methods
      # @api public
      def configure(&block)
        raise FrozenConfig, 'Cannot modify frozen config' if frozen?

        yield(config) if block
        self
      end

      # Finalize and freeze configuration
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def finalize!
        return self if config.frozen?

        config.finalize!
        self
      end
    end
  end
end
