module IceCube

  module Validations::MonthlyInterval

    def interval(interval)
      interval = normalized_interval(interval)
      verify_alignment(interval, :month, :interval) { |error| raise error }

      @interval = interval
      replace_validations_for(:interval, [Validation.new(@interval)])
      clobber_base_validations(:month)
      self
    end

    class Validation

      attr_reader :interval

      def initialize(interval)
        @interval = interval
      end

      def type
        :month
      end

      def dst_adjust?
        true
      end

      def validate(step_time, start_time)
        t0, t1 = start_time, step_time
        months = (t1.month - t0.month) +
                 (t1.year - t0.year) * 12
        offset = (months % interval).nonzero?
        interval - offset if offset
      end

      def build_s(builder)
        builder.base = IceCube::I18n.t('ice_cube.each_month', count: interval)
      end

      def build_hash(builder)
        builder[:interval] = interval
      end

      def build_ical(builder)
        builder['FREQ'] << 'MONTHLY'
        builder['INTERVAL'] << interval unless interval == 1
      end

    end

  end

end
