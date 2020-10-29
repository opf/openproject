module IceCube

  module Validations::SecondlyInterval

    def interval(interval)
      verify_alignment(interval, :sec, :interval) { |error| raise error }

      @interval = normalized_interval(interval)
      replace_validations_for(:interval, [Validation.new(@interval)])
      clobber_base_validations(:sec)
      self
    end

    class Validation

      attr_reader :interval

      def initialize(interval)
        @interval = interval
      end

      def type
        :sec
      end

      def dst_adjust?
        false
      end

      def validate(step_time, start_time)
        seconds = step_time.to_i - start_time.to_i
        offset = (seconds % interval).nonzero?
        interval - offset if offset
      end

      def build_s(builder)
        builder.base = IceCube::I18n.t("ice_cube.each_second", count: interval)
      end

      def build_hash(builder)
        builder[:interval] = interval
      end

      def build_ical(builder)
        builder['FREQ'] << 'SECONDLY'
        builder['INTERVAL'] << interval unless interval == 1
      end

    end

  end

end
