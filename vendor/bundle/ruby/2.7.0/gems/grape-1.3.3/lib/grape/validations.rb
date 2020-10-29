# frozen_string_literal: true

module Grape
  # Registry to store and locate known Validators.
  module Validations
    class << self
      attr_accessor :validators
    end

    self.validators = {}

    # Register a new validator, so it can be used to validate parameters.
    # @param short_name [String] all lower-case, no spaces
    # @param klass [Class] the validator class. Should inherit from
    #   Validations::Base.
    def self.register_validator(short_name, klass)
      validators[short_name] = klass
    end

    def self.deregister_validator(short_name)
      validators.delete(short_name)
    end
  end
end
