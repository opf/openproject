module IceCube

  module Validations::HourOfDay

    # Add hour of day validations
    def hour_of_day(*hours)
      hours.flatten.each do |hour|
        unless hour.is_a?(Integer)
          raise ArgumentError, "expecting Integer value for hour, got #{hour.inspect}"
        end

        verify_alignment(hour, :hour, :hour_of_day) { |error| raise error }

        validations_for(:hour_of_day) << Validation.new(hour)
      end
      clobber_base_validations(:hour)
      self
    end

    def realign(opening_time, start_time)
      return super unless validations[:hour_of_day]
      freq = base_interval_validation.interval

      first_hour = Array(validations[:hour_of_day]).min_by(&:value)
      time = TimeUtil::TimeWrapper.new(start_time, false)
      if freq > 1
        offset = first_hour.validate(opening_time, start_time)
        time.add(:hour, offset - freq)
      else
        time.hour = first_hour.value
      end

      super opening_time, time.to_time
    end

    class Validation < Validations::FixedValue

      attr_reader :hour
      alias :value :hour

      def initialize(hour)
        @hour = hour
      end

      def key
        :hour_of_day
      end

      def type
        :hour
      end

      def dst_adjust?
        true
      end

      def build_s(builder)
        builder.piece(:hour_of_day) << StringBuilder.nice_number(hour)
      end

      def build_hash(builder)
        builder.validations_array(:hour_of_day) << hour
      end

      def build_ical(builder)
        builder['BYHOUR'] << hour
      end

      StringBuilder.register_formatter(:hour_of_day) do |segments|
        str = StringBuilder.sentence(segments)
        IceCube::I18n.t('ice_cube.at_hours_of_the_day', count: segments.size, segments: str)
      end

    end

  end

end
