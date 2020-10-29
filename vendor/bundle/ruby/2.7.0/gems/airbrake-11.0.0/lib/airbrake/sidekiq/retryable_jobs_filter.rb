# frozen_string_literal: true

module Airbrake
  module Sidekiq
    # Filter that can ignore notices from jobs that failed but will be retried
    # by Sidekiq
    # @since v7.3.0
    class RetryableJobsFilter
      if Gem::Version.new(::Sidekiq::VERSION) < Gem::Version.new('5.0.0')
        require 'sidekiq/middleware/server/retry_jobs'
        DEFAULT_MAX_RETRY_ATTEMPTS = \
          ::Sidekiq::Middleware::Server::RetryJobs::DEFAULT_MAX_RETRY_ATTEMPTS
      else
        require 'sidekiq/job_retry'
        DEFAULT_MAX_RETRY_ATTEMPTS = ::Sidekiq::JobRetry::DEFAULT_MAX_RETRY_ATTEMPTS
      end

      def initialize(max_retries: nil)
        @max_retries = max_retries
      end

      def call(notice)
        job = notice[:params][:job]

        notice.ignore! if retryable?(job)
      end

      private

      def retryable?(job)
        return false unless job && job['retry']

        max_attempts = max_attempts_for(job)
        retry_count = (job['retry_count'] || -1) + 1
        retry_count < max_attempts
      end

      def max_attempts_for(job)
        if @max_retries
          @max_retries
        elsif job['retry'].is_a?(Integer)
          job['retry']
        else
          max_retries
        end
      end

      def max_retries
        @max_retries ||= ::Sidekiq.options[:max_retries] || DEFAULT_MAX_RETRY_ATTEMPTS
      end
    end
  end
end
