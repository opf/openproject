class Time
  class << self
    module NowWithFixedTime
      def now
        if @fixed_time
          @fixed_time.dup
        else
          super
        end
      end
    end
    prepend NowWithFixedTime

    def fix(time = Time.now)
      @fixed_time = time
      yield
    ensure
      @fixed_time = nil
    end
  end
end
