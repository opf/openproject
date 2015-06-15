module UiComponents
  module Dsl
    module Conditionable
      module InstanceMethods
        def show?(attributes = {})
          attributes.fetch(:if, true) && !attributes.fetch(:unless, false)
        end
      end

      def self.included(receiver)
        receiver.send :include, InstanceMethods
      end
    end
  end
end
