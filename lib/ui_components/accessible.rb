module UiComponents
  module Accessible
    module ClassMethods
      attr_accessor :accessible_role, :aria_attributes

      def role(symbol, &block)
        return @accessible_role = symbol unless block_given?
        @accessible_role = block
      end

      def aria(attributes = {})
        @aria_attributes ||= {}
        attributes.each do |k, v|
          @aria_attributes["aria-#{k}"] = v
        end
      end
    end

    module InstanceMethods
      def role
        if self.class.accessible_role.is_a?(Proc)
          @role = instance_eval(&self.class.accessible_role)
        else
          @role = self.class.accessible_role
        end
      end

      def aria_attributes
        self.class.aria_attributes || {}
      end

      def accessible_attributes
        return aria_attributes if role.nil?
        aria_attributes.merge(role: role)
      end
    end

    def self.included(receiver)
      receiver.extend ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end
