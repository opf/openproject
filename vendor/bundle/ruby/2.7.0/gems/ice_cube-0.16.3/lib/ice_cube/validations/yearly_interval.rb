module IceCube

  module Validations::YearlyInterval

    def interval(interval)
      @interval = normalized_interval(interval)
      replace_validations_for(:interval, [Validation.new(@interval)])
      clobber_base_validations(:year)
      self
    end

    class Validation

      attr_reader :interval

      def initialize(interval)
        @interval = interval
      end

      def type
        :year
      end

      def dst_adjust?
        true
      end

      def validate(step_time, start_time)
        years = step_time.year - start_time.year
        offset = (years % interval).nonzero?
        interval - offset if offset
      end

      def build_s(builder)
        builder.base = IceCube::I18n.t('ice_cube.each_year', count: interval)
      end

      def build_hash(builder)
        builder[:interval] = interval
      end

      def build_ical(builder)
        builder['FREQ'] << 'YEARLY'
        unless interval == 1
          builder['INTERVAL'] << interval
        end
      end

    end

  end

end
