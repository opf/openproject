# frozen_string_literal: true

require 'concurrent/array'

require 'dry/configurable/constants'
require 'dry/configurable/class_methods'
require 'dry/configurable/instance_methods'
require 'dry/configurable/config'
require 'dry/configurable/setting'
require 'dry/configurable/errors'

module Dry
  # A simple configuration mixin
  #
  # @example class-level configuration
  #
  #   class App
  #     extend Dry::Configurable
  #
  #     setting :database do
  #       setting :dsn, 'sqlite:memory'
  #     end
  #   end
  #
  #   App.config.database.dsn = 'jdbc:sqlite:memory'
  #   App.config.database.dsn
  #     # => "jdbc:sqlite:memory"
  #
  # @example instance-level configuration
  #
  #   class App
  #     include Dry::Configurable
  #
  #     setting :database
  #   end
  #
  #   production = App.new
  #   production.config.database = ENV['DATABASE_URL']
  #   production.finalize!
  #
  #   development = App.new
  #   development.config.database = 'jdbc:sqlite:memory'
  #   development.finalize!
  #
  # @api public
  module Configurable
    # @api private
    def self.extended(klass)
      super
      klass.extend(ClassMethods)
    end

    # @api private
    def self.included(klass)
      raise AlreadyIncluded if klass.include?(InstanceMethods)

      super
      klass.class_eval do
        extend(ClassMethods)
        include(InstanceMethods)

        class << self
          undef :config
          undef :configure
        end
      end
    end
  end
end
