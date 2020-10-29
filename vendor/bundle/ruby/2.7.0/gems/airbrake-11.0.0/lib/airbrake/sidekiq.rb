# frozen_string_literal: true

require 'airbrake/sidekiq/retryable_jobs_filter'

module Airbrake
  module Sidekiq
    # Provides integration with Sidekiq v2+.
    class ErrorHandler
      def call(_worker, context, _queue)
        timing = Airbrake::Benchmark.measure do
          yield
        end
      rescue Exception => exception # rubocop:disable Lint/RescueException
        notify_airbrake(exception, context)
        Airbrake.notify_queue(
          queue: context['class'],
          error_count: 1,
          timing: 0.01,
        )
        raise exception
      else
        Airbrake.notify_queue(
          queue: context['class'],
          error_count: 0,
          timing: timing,
        )
      end

      private

      def notify_airbrake(exception, context)
        Airbrake.notify(exception, job: context) do |notice|
          notice[:context][:component] = 'sidekiq'
          notice[:context][:action] = action(context)
        end
      end

      # @return [String] job's name. When ActiveJob is present, retrieve
      #   job_class. When used directly, use worker's name
      def action(context)
        klass = context['class'] || context[:job] && context[:job]['class']
        return klass unless context[:job] && context[:job]['args'].first.is_a?(Hash)
        return klass unless (job_class = context[:job]['args'].first['job_class'])

        job_class
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add(Airbrake::Sidekiq::ErrorHandler)
  end
end
