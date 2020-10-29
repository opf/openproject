# frozen_string_literal: true

module Grape
  module Validations
    class SameAsValidator < Base
      def validate_param!(attr_name, params)
        confirmation = options_key?(:value) ? @option[:value] : @option
        return if params[attr_name] == params[confirmation]
        raise Grape::Exceptions::Validation.new(
          params: [@scope.full_name(attr_name)],
          message: build_message
        )
      end

      private

      def build_message
        if options_key?(:message)
          @option[:message]
        else
          format I18n.t(:same_as, scope: 'grape.errors.messages'), parameter: @option
        end
      end
    end
  end
end
