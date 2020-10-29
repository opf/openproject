module DelayedCronJob
  class Plugin < Delayed::Plugin

    class << self
      def cron?(job)
        job.cron.present?
      end
    end

    callbacks do |lifecycle|

      # Prevent rescheduling of failed jobs as this is already done
      # after perform.
      lifecycle.around(:error) do |worker, job, &block|
        if cron?(job)
          job.error = $ERROR_INFO
          worker.job_say(job,
                         "FAILED with #{$ERROR_INFO.class.name}: #{$ERROR_INFO.message}",
                         Logger::ERROR)
        else
          # No cron job - proceed as normal
          block.call(worker, job)
        end
      end

      # Reset the last_error to have the correct status of the last run.
      lifecycle.before(:perform) do |worker, job|
        job.last_error = nil if cron?(job)
      end

      # Prevent destruction of cron jobs
      lifecycle.after(:invoke_job) do |job|
        job.schedule_instead_of_destroy = true if cron?(job)
      end

      # Schedule the next run based on the cron attribute.
      lifecycle.after(:perform) do |worker, job|
        if cron?(job) && !job.destroyed?
          job.cron = job.class.where(:id => job.id).pluck(:cron).first
          if job.cron.present?
            job.schedule_next_run
          else
            job.schedule_instead_of_destroy = false
            job.destroy
          end
        end
      end
    end
  end
end
