# frozen_string_literal: true

require 'grape/validations/validators/multiple_params_base'

module Grape
  module Validations
    class AllOrNoneOfValidator < MultipleParamsBase
      def validate_params!(params)
        keys = keys_in_common(params)
        return if keys.empty? || keys.length == all_keys.length
        raise Grape::Exceptions::Validation.new(params: all_keys, message: message(:all_or_none))
      end
    end
  end
end
