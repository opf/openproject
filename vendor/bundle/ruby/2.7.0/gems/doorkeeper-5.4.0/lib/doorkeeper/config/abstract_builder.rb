# frozen_string_literal: true

module Doorkeeper
  class Config
    # Abstract base class for Doorkeeper and it's extensions configuration
    # builder. Instantiates and validates gem configuration.
    #
    class AbstractBuilder
      attr_reader :config

      # @param [Class] config class
      #
      def initialize(config = Config.new, &block)
        @config = config
        instance_eval(&block)
      end

      # Builds and validates configuration.
      #
      # @return [Doorkeeper::Config] config instance
      #
      def build
        @config.validate! if @config.respond_to?(:validate!)
        @config
      end
    end
  end
end
