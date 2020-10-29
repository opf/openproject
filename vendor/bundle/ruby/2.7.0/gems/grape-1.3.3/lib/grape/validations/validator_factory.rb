# frozen_string_literal: true

module Grape
  module Validations
    class ValidatorFactory
      def self.create_validator(**options)
        options[:validator_class].new(options[:attributes],
                                      options[:options],
                                      options[:required],
                                      options[:params_scope],
                                      options[:opts])
      end
    end
  end
end
