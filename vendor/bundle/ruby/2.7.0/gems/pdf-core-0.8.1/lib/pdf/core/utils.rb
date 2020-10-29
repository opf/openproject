# frozen_string_literal: true

module PDF
  module Core
    module Utils
      def deep_clone(object)
        Marshal.load(Marshal.dump(object))
      end
      module_function :deep_clone
    end
  end
end
