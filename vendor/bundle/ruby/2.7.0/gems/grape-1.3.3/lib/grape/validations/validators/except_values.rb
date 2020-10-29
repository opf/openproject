# frozen_string_literal: true

module Grape
  module Validations
    class ExceptValuesValidator < Base
      def initialize(attrs, options, required, scope, opts = {})
        @except = options.is_a?(Hash) ? options[:value] : options
        super
      end

      def validate_param!(attr_name, params)
        return unless params.respond_to?(:key?) && params.key?(attr_name)

        excepts = @except.is_a?(Proc) ? @except.call : @except
        return if excepts.nil?

        param_array = params[attr_name].nil? ? [nil] : Array.wrap(params[attr_name])
        raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: message(:except_values)) if param_array.any? { |param| excepts.include?(param) }
      end
    end
  end
end
