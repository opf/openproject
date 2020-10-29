# frozen_string_literal: true

module Grape
  module Validations
    class RegexpValidator < Base
      def validate_param!(attr_name, params)
        return unless params.respond_to?(:key?) && params.key?(attr_name)
        return if Array.wrap(params[attr_name]).all? { |param| param.nil? || param.to_s.match?((options_key?(:value) ? @option[:value] : @option)) }
        raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: message(:regexp))
      end
    end
  end
end
