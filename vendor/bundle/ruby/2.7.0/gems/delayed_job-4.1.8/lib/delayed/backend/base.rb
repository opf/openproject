module Delayed
  module Backend
    module Base
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        # Add a job to the queue
        def enqueue(*args)
          job_options = Delayed::Backend::JobPreparer.new(*args).prepare
          enqueue_job(job_options)
        end

        def enqueue_job(options)
          new(options).tap do |job|
            Delayed::Worker.lifecycle.run_callbacks(:enqueue, job) do
              job.hook(:enqueue)
              Delayed::Worker.delay_job?(job) ? job.save : job.invoke_job
            end
          end
        end

        def reserve(worker, max_run_time = Worker.max_run_time)
          # We get up to 5 jobs from the db. In case we cannot get exclusive access to a job we try the next.
          # this leads to a more even distribution of jobs across the worker processes
          find_available(worker.name, worker.read_ahead, max_run_time).detect do |job|
            job.lock_exclusively!(max_run_time, worker.name)
          end
        end

        # Allow the backend to attempt recovery from reserve errors
        def recover_from(_error); end

        # Hook method that is called before a new worker is forked
        def before_fork; end

        # Hook method that is called after a new worker is forked
        def after_fork; end

        def work_off(num = 100)
          warn '[DEPRECATION] `Delayed::Job.work_off` is deprecated. Use `Delayed::Worker.new.work_off instead.'
          Delayed::Worker.new.work_off(num)
        end
      end

      attr_reader :error
      def error=(error)
        @error = error
        self.last_error = "#{error.message}\n#{error.backtrace.join("\n")}" if respond_to?(:last_error=)
      end

      def failed?
        !!failed_at
      end
      alias_method :failed, :failed?

      ParseObjectFromYaml = %r{\!ruby/\w+\:([^\s]+)} # rubocop:disable ConstantName

      def name
        @name ||= payload_object.respond_to?(:display_name) ? payload_object.display_name : payload_object.class.name
      rescue DeserializationError
        ParseObjectFromYaml.match(handler)[1]
      end

      def payload_object=(object)
        @payload_object = object
        self.handler = object.to_yaml
      end

      def payload_object
        @payload_object ||= YAML.load_dj(handler)
      rescue TypeError, LoadError, NameError, ArgumentError, SyntaxError, Psych::SyntaxError => e
        raise DeserializationError, "Job failed to load: #{e.message}. Handler: #{handler.inspect}"
      end

      def invoke_job
        Delayed::Worker.lifecycle.run_callbacks(:invoke_job, self) do
          begin
            hook :before
            payload_object.perform
            hook :success
          rescue Exception => e # rubocop:disable RescueException
            hook :error, e
            raise e
          ensure
            hook :after
          end
        end
      end

      # Unlock this job (note: not saved to DB)
      def unlock
        self.locked_at    = nil
        self.locked_by    = nil
      end

      def hook(name, *args)
        if payload_object.respond_to?(name)
          method = payload_object.method(name)
          method.arity.zero? ? method.call : method.call(self, *args)
        end
      rescue DeserializationError # rubocop:disable HandleExceptions
      end

      def reschedule_at
        if payload_object.respond_to?(:reschedule_at)
          payload_object.reschedule_at(self.class.db_time_now, attempts)
        else
          self.class.db_time_now + (attempts**4) + 5
        end
      end

      def max_attempts
        payload_object.max_attempts if payload_object.respond_to?(:max_attempts)
      end

      def max_run_time
        return unless payload_object.respond_to?(:max_run_time)
        return unless (run_time = payload_object.max_run_time)

        if run_time > Delayed::Worker.max_run_time
          Delayed::Worker.max_run_time
        else
          run_time
        end
      end

      def destroy_failed_jobs?
        payload_object.respond_to?(:destroy_failed_jobs?) ? payload_object.destroy_failed_jobs? : Delayed::Worker.destroy_failed_jobs
      rescue DeserializationError
        Delayed::Worker.destroy_failed_jobs
      end

      def fail!
        self.failed_at = self.class.db_time_now
        save!
      end

    protected

      def set_default_run_at
        self.run_at ||= self.class.db_time_now
      end

      # Call during reload operation to clear out internal state
      def reset
        @payload_object = nil
      end
    end
  end
end
