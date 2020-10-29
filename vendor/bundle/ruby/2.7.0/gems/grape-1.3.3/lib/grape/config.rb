# frozen_string_literal: true

module Grape
  module Config
    class Configuration
      ATTRIBUTES = %i[
        param_builder
      ].freeze

      attr_accessor(*ATTRIBUTES)

      def initialize
        reset
      end

      def reset
        self.param_builder = Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder
      end
    end

    def self.extended(base)
      def base.configure
        block_given? ? yield(config) : config
      end

      def base.config
        @configuration ||= Grape::Config::Configuration.new
      end
    end
  end
end

Grape.extend Grape::Config
Grape.config.reset
