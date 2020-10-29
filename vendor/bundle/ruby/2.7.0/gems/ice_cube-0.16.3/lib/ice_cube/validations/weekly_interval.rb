module IceCube

  module Validations::WeeklyInterval

    def interval(interval, week_start = :sunday)
      @interval = normalized_interval(interval)
      @week_start = TimeUtil.wday_to_sym(week_start)
      replace_validations_for(:interval, [Validation.new(@interval, week_start)])
      clobber_base_validations(:day)
      self
    end

    class Validation

      attr_reader :interval, :week_start

      def initialize(interval, week_start)
        @interval = interval
        @week_start = week_start
      end

      def type
        :day
      end

      def dst_adjust?
        true
      end

      def validate(step_time, start_time)
        return if step_time < start_time
        t0, t1 = start_time, step_time
        d0 = Date.new(t0.year, t0.month, t0.day)
        d1 = Date.new(t1.year, t1.month, t1.day)
        days = (d1 - TimeUtil.normalize_wday(d1.wday, week_start)) -
               (d0 - TimeUtil.normalize_wday(d0.wday, week_start))
        offset = ((days.to_i / 7) % interval).nonzero?
        (interval - offset) * 7 if offset
      end

      def build_s(builder)
        builder.base = IceCube::I18n.t('ice_cube.each_week', count: interval)
      end

      def build_hash(builder)
        builder[:interval] = interval
        builder[:week_start] = TimeUtil.sym_to_wday(week_start)
      end

      def build_ical(builder)
        builder['FREQ'] << 'WEEKLY'
        unless interval == 1
          builder['INTERVAL'] << interval
          builder['WKST'] << week_start.to_s.upcase[0..1]
        end
      end

    end

  end

end
