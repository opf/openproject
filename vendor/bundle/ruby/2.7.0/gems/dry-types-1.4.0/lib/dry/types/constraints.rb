# frozen_string_literal: true

require 'dry/logic/rule_compiler'
require 'dry/logic/predicates'
require 'dry/logic/rule/predicate'

module Dry
  # Helper methods for constraint types
  #
  # @api public
  module Types
    # @param [Hash] options
    #
    # @return [Dry::Logic::Rule]
    #
    # @api public
    def self.Rule(options)
      rule_compiler.(
        options.map { |key, val|
          Logic::Rule::Predicate.build(
            Logic::Predicates[:"#{key}?"]
          ).curry(val).to_ast
        }
      ).reduce(:and)
    end

    # @return [Dry::Logic::RuleCompiler]
    #
    # @api private
    def self.rule_compiler
      @rule_compiler ||= Logic::RuleCompiler.new(Logic::Predicates)
    end
  end
end
