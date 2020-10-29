# frozen_string_literal: true

require 'grape/validations/validators/multiple_params_base'

module Grape
  module Validations
    class AtLeastOneOfValidator < MultipleParamsBase
      def validate_params!(params)
        return unless keys_in_common(params).empty?
        raise Grape::Exceptions::Validation.new(params: all_keys, message: message(:at_least_one))
      end
    end
  end
end
