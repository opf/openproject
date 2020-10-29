module DelayedCronJob
  module Backend
    module UpdatableCron

      def self.included(klass)
        klass.send(:before_save, :set_next_run_at, :if => :cron_changed?)
        klass.attr_accessor :schedule_instead_of_destroy
      end

      def set_next_run_at
        if cron.present?
          self.run_at = Cronline.new(cron).next_time(Delayed::Job.db_time_now)
        end
      end

      def destroy
        super unless schedule_instead_of_destroy
      end

      def schedule_next_run
        self.attempts += 1
        unlock
        set_next_run_at
        save!
      end

    end
  end
end
