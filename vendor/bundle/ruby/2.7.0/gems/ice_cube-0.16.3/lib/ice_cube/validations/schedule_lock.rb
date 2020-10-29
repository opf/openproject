module IceCube

  module Validations::ScheduleLock

    # Lock the given time units to the units from schedule's +start_time+
    # These locks are all clobberable by other rules of the same #type
    # using +clobber_base_validation+
    #
    def schedule_lock(*types)
      types.each do |type|
        validations_for(:"base_#{type}") << Validation.new(type)
      end
    end

    class Validation < Validations::FixedValue

      attr_reader :type, :value

      def initialize(type)
        @type = type
      end

      def key
        :base
      end

      def dst_adjust?
        case @type
        when :sec, :min then false
        else true
        end
      end

      # no -op
      def build_s(builder)
      end

      # no -op
      def build_hash(builder)
      end

      # no -op
      def build_ical(builder)
      end

    end

  end

end
