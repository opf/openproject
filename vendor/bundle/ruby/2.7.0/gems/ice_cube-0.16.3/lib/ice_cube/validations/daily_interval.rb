module IceCube

  module Validations::DailyInterval

    # Add a new interval validation
    def interval(interval)
      interval = normalized_interval(interval)
      verify_alignment(interval, :wday, :interval) { |error| raise error }
      verify_alignment(interval, :day, :interval)  { |error| raise error }

      @interval = interval
      replace_validations_for(:interval, [Validation.new(@interval)])
      clobber_base_validations(:wday, :day)
      self
    end

    class Validation

      attr_reader :interval

      def initialize(interval)
        @interval = interval
      end

      def type
        :day
      end

      def dst_adjust?
        true
      end

      def validate(step_time, start_time)
        t0, t1 = start_time, step_time
        days = Date.new(t1.year, t1.month, t1.day) -
               Date.new(t0.year, t0.month, t0.day)
        offset = (days % interval).nonzero?
        interval - offset if offset
      end

      def build_s(builder)
        builder.base = IceCube::I18n.t('ice_cube.each_day', count: interval)
      end

      def build_hash(builder)
        builder[:interval] = interval
      end

      def build_ical(builder)
        builder['FREQ'] << 'DAILY'
        builder['INTERVAL'] << interval unless interval == 1
      end

    end

  end

end
