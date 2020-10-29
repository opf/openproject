module IceCube

  module Validations::Day

    def day(*days)
      days = days.flatten
      return self if days.empty?
      days.flatten.each do |day|
        unless day.is_a?(Integer) || day.is_a?(Symbol)
          raise ArgumentError, "expecting Integer or Symbol value for day, got #{day.inspect}"
        end
        day = TimeUtil.sym_to_wday(day)
        verify_alignment(day, :wday, :day) { |error| raise error }

        validations_for(:day) << Validation.new(day)
      end
      clobber_base_validations(:wday, :day)
      self
    end

    class Validation < Validations::FixedValue

      attr_reader :day
      alias :value :day

      def initialize(day)
        @day = day
      end

      def key
        :day
      end

      def type
        :wday
      end

      def dst_adjust?
        true
      end

      def build_s(builder)
        builder.piece(:day) << day
      end

      def build_hash(builder)
        builder.validations_array(:day) << day
      end

      def build_ical(builder)
        ical_day = IcalBuilder.fixnum_to_ical_day(day)
        # Only add if there aren't others from day_of_week that override
        if builder['BYDAY'].none? { |b| b.end_with?(ical_day) }
          builder['BYDAY'] << ical_day
        end
      end

      StringBuilder.register_formatter(:day) do |validation_days|
        # sort the days
        validation_days.sort!
        # pick the right shortening, if applicable
        if validation_days == [0, 6]
          IceCube::I18n.t('ice_cube.on_weekends')
        elsif validation_days == (1..5).to_a
          IceCube::I18n.t('ice_cube.on_weekdays')
        else
          day_names = ->(d){ "#{IceCube::I18n.t("ice_cube.days_on")[d]}" }
          segments = validation_days.map(&day_names)
          IceCube::I18n.t('ice_cube.on_days', days: StringBuilder.sentence(segments))
        end
      end

    end

  end

end
