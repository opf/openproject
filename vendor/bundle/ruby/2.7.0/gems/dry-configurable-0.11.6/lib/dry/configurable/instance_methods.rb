# frozen_string_literal: true

require 'dry/configurable/config'
require 'dry/configurable/methods'

module Dry
  module Configurable
    # Instance-level API when `Dry::Configurable` is included in a class
    #
    # @api public
    module InstanceMethods
      include Methods

      # Return object's configuration
      #
      # @return [Config]
      #
      # @api public
      attr_reader :config

      # @api private
      def initialize(*)
        @config = Config.new(self.class._settings.dup)
        super
      end

      # Finalize the config and freeze the object
      #
      # @api public
      def finalize!
        return self if frozen?

        super
        freeze
      end

      private

      # @api public
      def initialize_copy(source)
        super
        @config = source.config.dup
      end
    end
  end
end
