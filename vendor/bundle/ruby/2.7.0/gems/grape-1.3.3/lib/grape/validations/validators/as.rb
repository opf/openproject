# frozen_string_literal: true

module Grape
  module Validations
    class AsValidator < Base
      def initialize(attrs, options, required, scope, opts = {})
        @renamed_options = options
        super
      end

      def validate_param!(attr_name, params)
        params[@renamed_options] = params[attr_name]
      end
    end
  end
end
