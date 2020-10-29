module IceCube

  module Validations::SecondOfMinute

    def second_of_minute(*seconds)
      seconds.flatten.each do |second|
        unless second.is_a?(Integer)
          raise ArgumentError, "Expecting Integer value for second, got #{second.inspect}"
        end

        verify_alignment(second, :sec, :second_of_minute) { |error| raise error }

        validations_for(:second_of_minute) << Validation.new(second)
      end
      clobber_base_validations :sec
      self
    end

    def realign(opening_time, start_time)
      return super unless validations[:second_of_minute]

      first_second = Array(validations[:second_of_minute]).min_by(&:value)
      time = TimeUtil::TimeWrapper.new(start_time, false)
      time.sec = first_second.value
      super opening_time, time.to_time
    end

    class Validation < Validations::FixedValue

      attr_reader :second
      alias :value :second

      def initialize(second)
        @second = second
      end

      def key
        :second_of_minute
      end

      def type
        :sec
      end

      def dst_adjust?
        false
      end

      def build_s(builder)
        builder.piece(:second_of_minute) << StringBuilder.nice_number(second)
      end

      def build_hash(builder)
        builder.validations_array(:second_of_minute) << second
      end

      def build_ical(builder)
        builder['BYSECOND'] << second
      end

      StringBuilder.register_formatter(:second_of_minute) do |segments|
        str = StringBuilder.sentence(segments)
        IceCube::I18n.t('ice_cube.on_seconds_of_minute', count: segments.size, segments: str)
      end

    end

  end

end
