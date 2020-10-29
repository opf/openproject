module IceCube

  module Validations::MinutelyInterval

    def interval(interval)
      verify_alignment(interval, :min, :interval) { |error| raise error }

      @interval = normalized_interval(interval)
      replace_validations_for(:interval, [Validation.new(@interval)])
      clobber_base_validations(:min)
      self
    end

    class Validation

      attr_reader :interval

      def initialize(interval)
        @interval = interval
      end

      def type
        :min
      end

      def dst_adjust?
        false
      end

      def validate(step_time, start_time)
        t0, t1 = start_time.to_i, step_time.to_i
        sec = (t1 - t1 % ONE_MINUTE) -
              (t0 - t0 % ONE_MINUTE)
        minutes = sec / ONE_MINUTE
        offset = (minutes % interval).nonzero?
        interval - offset if offset
      end

      def build_s(builder)
        builder.base = IceCube::I18n.t('ice_cube.each_minute', count: interval)
      end

      def build_hash(builder)
        builder[:interval] = interval
      end

      def build_ical(builder)
        builder['FREQ'] << 'MINUTELY'
        builder['INTERVAL'] << interval unless interval == 1
      end

    end

  end

end
