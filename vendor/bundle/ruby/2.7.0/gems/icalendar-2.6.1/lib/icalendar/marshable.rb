module Icalendar
  module Marshable
    def self.included(base)
      base.extend ClassMethods
    end

    def marshal_dump
      instance_variables
        .reject { |ivar| self.class.transient_variables.include?(ivar) }
        .each_with_object({}) do |ivar, serialized|

        serialized[ivar] = instance_variable_get(ivar)
      end
    end

    def marshal_load(serialized)
      serialized.each do |ivar, value|
        unless self.class.transient_variables.include?(ivar)
          instance_variable_set(ivar, value)
        end
      end
    end

    module ClassMethods
      def transient_variables
        @transient_variables ||= [:@transient_variables]
      end

      def transient_variable(name)
        transient_variables.push(name.to_sym)
      end
    end
  end
end
