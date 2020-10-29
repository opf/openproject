module DelayedCronJob
  module ActiveJob
    module QueueAdapter

      def self.included(klass)
        klass.send(:alias_method, :enqueue, :enqueue_with_cron)
        klass.send(:alias_method, :enqueue_at, :enqueue_at_with_cron)
      end

      def self.extended(klass)
        meta = class << klass; self; end
        meta.send(:alias_method, :enqueue, :enqueue_with_cron)
        meta.send(:alias_method, :enqueue_at, :enqueue_at_with_cron)
      end

      def enqueue_with_cron(job)
        enqueue_at(job, nil)
      end

      def enqueue_at_with_cron(job, timestamp)
        options = { queue: job.queue_name,
                    cron: job.cron  }
        options[:run_at] = Time.at(timestamp) if timestamp
        options[:priority] = job.priority if job.respond_to?(:priority)
        wrapper = ::ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(job.serialize)
        delayed_job = Delayed::Job.enqueue(wrapper, options)
        job.provider_job_id = delayed_job.id if job.respond_to?(:provider_job_id=)
        delayed_job
      end

    end
  end
end