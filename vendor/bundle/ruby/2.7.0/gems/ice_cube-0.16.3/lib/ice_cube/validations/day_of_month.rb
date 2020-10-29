module IceCube

  module Validations::DayOfMonth

    def day_of_month(*days)
      days.flatten.each do |day|
        unless day.is_a?(Integer)
          raise ArgumentError, "expecting Integer value for day, got #{day.inspect}"
        end
        verify_alignment(day, :day, :day_of_month) { |error| raise error }
        validations_for(:day_of_month) << Validation.new(day)
      end
      clobber_base_validations(:day, :wday)
      self
    end

    class Validation < Validations::FixedValue

      attr_reader :day
      alias :value :day

      def initialize(day)
        @day = day
      end

      def key
        :day_of_month
      end

      def type
        :day
      end

      def dst_adjust?
        true
      end

      def build_s(builder)
        builder.piece(:day_of_month) << StringBuilder.nice_number(day)
      end

      def build_hash(builder)
        builder.validations_array(:day_of_month) << day
      end

      def build_ical(builder)
        builder['BYMONTHDAY'] << day
      end

      StringBuilder.register_formatter(:day_of_month) do |entries|
        sentence = StringBuilder.sentence(entries)
        str = IceCube::I18n.t('ice_cube.days_of_month', count: entries.size, segments: sentence)
        IceCube::I18n.t('ice_cube.on', sentence: str)
      end

    end

  end

end
