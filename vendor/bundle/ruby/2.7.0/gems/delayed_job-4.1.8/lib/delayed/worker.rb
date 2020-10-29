require 'timeout'
require 'active_support/dependencies'
require 'active_support/core_ext/numeric/time'
require 'active_support/core_ext/class/attribute_accessors'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/hash/indifferent_access'
require 'logger'
require 'benchmark'

module Delayed
  class Worker # rubocop:disable ClassLength
    DEFAULT_LOG_LEVEL        = 'info'.freeze
    DEFAULT_SLEEP_DELAY      = 5
    DEFAULT_MAX_ATTEMPTS     = 25
    DEFAULT_MAX_RUN_TIME     = 4.hours
    DEFAULT_DEFAULT_PRIORITY = 0
    DEFAULT_DELAY_JOBS       = true
    DEFAULT_QUEUES           = [].freeze
    DEFAULT_QUEUE_ATTRIBUTES = HashWithIndifferentAccess.new.freeze
    DEFAULT_READ_AHEAD       = 5

    cattr_accessor :min_priority, :max_priority, :max_attempts, :max_run_time,
                   :default_priority, :sleep_delay, :logger, :delay_jobs, :queues,
                   :read_ahead, :plugins, :destroy_failed_jobs, :exit_on_complete,
                   :default_log_level

    # Named queue into which jobs are enqueued by default
    cattr_accessor :default_queue_name

    cattr_reader :backend, :queue_attributes

    # name_prefix is ignored if name is set directly
    attr_accessor :name_prefix

    def self.reset
      self.default_log_level = DEFAULT_LOG_LEVEL
      self.sleep_delay       = DEFAULT_SLEEP_DELAY
      self.max_attempts      = DEFAULT_MAX_ATTEMPTS
      self.max_run_time      = DEFAULT_MAX_RUN_TIME
      self.default_priority  = DEFAULT_DEFAULT_PRIORITY
      self.delay_jobs        = DEFAULT_DELAY_JOBS
      self.queues            = DEFAULT_QUEUES
      self.queue_attributes  = DEFAULT_QUEUE_ATTRIBUTES
      self.read_ahead        = DEFAULT_READ_AHEAD
      @lifecycle             = nil
    end

    # Add or remove plugins in this list before the worker is instantiated
    self.plugins = [Delayed::Plugins::ClearLocks]

    # By default failed jobs are destroyed after too many attempts. If you want to keep them around
    # (perhaps to inspect the reason for the failure), set this to false.
    self.destroy_failed_jobs = true

    # By default, Signals INT and TERM set @exit, and the worker exits upon completion of the current job.
    # If you would prefer to raise a SignalException and exit immediately you can use this.
    # Be aware daemons uses TERM to stop and restart
    # false - No exceptions will be raised
    # :term - Will only raise an exception on TERM signals but INT will wait for the current job to finish
    # true - Will raise an exception on TERM and INT
    cattr_accessor :raise_signal_exceptions
    self.raise_signal_exceptions = false

    def self.backend=(backend)
      if backend.is_a? Symbol
        require "delayed/serialization/#{backend}"
        require "delayed/backend/#{backend}"
        backend = "Delayed::Backend::#{backend.to_s.classify}::Job".constantize
      end
      @@backend = backend # rubocop:disable ClassVars
      silence_warnings { ::Delayed.const_set(:Job, backend) }
    end

    # rubocop:disable ClassVars
    def self.queue_attributes=(val)
      @@queue_attributes = val.with_indifferent_access
    end

    def self.guess_backend
      warn '[DEPRECATION] guess_backend is deprecated. Please remove it from your code.'
    end

    def self.before_fork
      unless @files_to_reopen
        @files_to_reopen = []
        ObjectSpace.each_object(File) do |file|
          @files_to_reopen << file unless file.closed?
        end
      end

      backend.before_fork
    end

    def self.after_fork
      # Re-open file handles
      @files_to_reopen.each do |file|
        begin
          file.reopen file.path, 'a+'
          file.sync = true
        rescue ::Exception # rubocop:disable HandleExceptions, RescueException
        end
      end
      backend.after_fork
    end

    def self.lifecycle
      # In case a worker has not been set up, job enqueueing needs a lifecycle.
      setup_lifecycle unless @lifecycle

      @lifecycle
    end

    def self.setup_lifecycle
      @lifecycle = Delayed::Lifecycle.new
      plugins.each { |klass| klass.new }
    end

    def self.reload_app?
      defined?(ActionDispatch::Reloader) && Rails.application.config.cache_classes == false
    end

    def self.delay_job?(job)
      if delay_jobs.is_a?(Proc)
        delay_jobs.arity == 1 ? delay_jobs.call(job) : delay_jobs.call
      else
        delay_jobs
      end
    end

    def initialize(options = {})
      @quiet = options.key?(:quiet) ? options[:quiet] : true
      @failed_reserve_count = 0

      [:min_priority, :max_priority, :sleep_delay, :read_ahead, :queues, :exit_on_complete].each do |option|
        self.class.send("#{option}=", options[option]) if options.key?(option)
      end

      # Reset lifecycle on the offhand chance that something lazily
      # triggered its creation before all plugins had been registered.
      self.class.setup_lifecycle
    end

    # Every worker has a unique name which by default is the pid of the process. There are some
    # advantages to overriding this with something which survives worker restarts:  Workers can
    # safely resume working on tasks which are locked by themselves. The worker will assume that
    # it crashed before.
    def name
      return @name unless @name.nil?
      "#{@name_prefix}host:#{Socket.gethostname} pid:#{Process.pid}" rescue "#{@name_prefix}pid:#{Process.pid}"
    end

    # Sets the name of the worker.
    # Setting the name to nil will reset the default worker name
    attr_writer :name

    def start # rubocop:disable CyclomaticComplexity, PerceivedComplexity
      trap('TERM') do
        Thread.new { say 'Exiting...' }
        stop
        raise SignalException, 'TERM' if self.class.raise_signal_exceptions
      end

      trap('INT') do
        Thread.new { say 'Exiting...' }
        stop
        raise SignalException, 'INT' if self.class.raise_signal_exceptions && self.class.raise_signal_exceptions != :term
      end

      say 'Starting job worker'

      self.class.lifecycle.run_callbacks(:execute, self) do
        loop do
          self.class.lifecycle.run_callbacks(:loop, self) do
            @realtime = Benchmark.realtime do
              @result = work_off
            end
          end

          count = @result[0] + @result[1]

          if count.zero?
            if self.class.exit_on_complete
              say 'No more jobs available. Exiting'
              break
            elsif !stop?
              sleep(self.class.sleep_delay)
              reload!
            end
          else
            say format("#{count} jobs processed at %.4f j/s, %d failed", count / @realtime, @result.last)
          end

          break if stop?
        end
      end
    end

    def stop
      @exit = true
    end

    def stop?
      !!@exit
    end

    # Do num jobs and return stats on success/failure.
    # Exit early if interrupted.
    def work_off(num = 100)
      success = 0
      failure = 0

      num.times do
        case reserve_and_run_one_job
        when true
          success += 1
        when false
          failure += 1
        else
          break # leave if no work could be done
        end
        break if stop? # leave if we're exiting
      end

      [success, failure]
    end

    def run(job)
      job_say job, 'RUNNING'
      runtime = Benchmark.realtime do
        Timeout.timeout(max_run_time(job).to_i, WorkerTimeout) { job.invoke_job }
        job.destroy
      end
      job_say job, format('COMPLETED after %.4f', runtime)
      return true # did work
    rescue DeserializationError => error
      job_say job, "FAILED permanently with #{error.class.name}: #{error.message}", 'error'

      job.error = error
      failed(job)
    rescue Exception => error # rubocop:disable RescueException
      self.class.lifecycle.run_callbacks(:error, self, job) { handle_failed_job(job, error) }
      return false # work failed
    end

    # Reschedule the job in the future (when a job fails).
    # Uses an exponential scale depending on the number of failed attempts.
    def reschedule(job, time = nil)
      if (job.attempts += 1) < max_attempts(job)
        time ||= job.reschedule_at
        job.run_at = time
        job.unlock
        job.save!
      else
        job_say job, "FAILED permanently because of #{job.attempts} consecutive failures", 'error'
        failed(job)
      end
    end

    def failed(job)
      self.class.lifecycle.run_callbacks(:failure, self, job) do
        begin
          job.hook(:failure)
        rescue => error
          say "Error when running failure callback: #{error}", 'error'
          say error.backtrace.join("\n"), 'error'
        ensure
          job.destroy_failed_jobs? ? job.destroy : job.fail!
        end
      end
    end

    def job_say(job, text, level = default_log_level)
      text = "Job #{job.name} (id=#{job.id})#{say_queue(job.queue)} #{text}"
      say text, level
    end

    def say(text, level = default_log_level)
      text = "[Worker(#{name})] #{text}"
      puts text unless @quiet
      return unless logger
      # TODO: Deprecate use of Fixnum log levels
      unless level.is_a?(String)
        level = Logger::Severity.constants.detect { |i| Logger::Severity.const_get(i) == level }.to_s.downcase
      end
      logger.send(level, "#{Time.now.strftime('%FT%T%z')}: #{text}")
    end

    def max_attempts(job)
      job.max_attempts || self.class.max_attempts
    end

    def max_run_time(job)
      job.max_run_time || self.class.max_run_time
    end

  protected

    def say_queue(queue)
      " (queue=#{queue})" if queue
    end

    def handle_failed_job(job, error)
      job.error = error
      job_say job, "FAILED (#{job.attempts} prior attempts) with #{error.class.name}: #{error.message}", 'error'
      reschedule(job)
    end

    # Run the next job we can get an exclusive lock on.
    # If no jobs are left we return nil
    def reserve_and_run_one_job
      job = reserve_job
      self.class.lifecycle.run_callbacks(:perform, self, job) { run(job) } if job
    end

    def reserve_job
      job = Delayed::Job.reserve(self)
      @failed_reserve_count = 0
      job
    rescue ::Exception => error # rubocop:disable RescueException
      say "Error while reserving job: #{error}"
      Delayed::Job.recover_from(error)
      @failed_reserve_count += 1
      raise FatalBackendError if @failed_reserve_count >= 10
      nil
    end

    def reload!
      return unless self.class.reload_app?
      if defined?(ActiveSupport::Reloader)
        Rails.application.reloader.reload!
      else
        ActionDispatch::Reloader.cleanup!
        ActionDispatch::Reloader.prepare!
      end
    end
  end
end

Delayed::Worker.reset
