# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      INTEGER_CLASS_NAME = 0.to_i.class.to_s.freeze

      def integer_class_name
        INTEGER_CLASS_NAME
      end
    end
  end
end
