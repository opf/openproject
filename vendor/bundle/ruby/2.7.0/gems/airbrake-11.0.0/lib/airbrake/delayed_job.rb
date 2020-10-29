# frozen_string_literal: true

module Delayed
  module Plugins
    # Provides integration with Delayed Job.
    # rubocop:disable Metrics/BlockLength
    class Airbrake < ::Delayed::Plugin
      callbacks do |lifecycle|
        lifecycle.around(:invoke_job) do |job, *args, &block|
          begin
            timing = ::Airbrake::Benchmark.measure do
              # Forward the call to the next callback in the callback chain
              block.call(job, *args)
            end
          rescue Exception => exception # rubocop:disable Lint/RescueException
            params = job.as_json

            # If DelayedJob is used through ActiveJob, it contains extra info.
            if job.payload_object.respond_to?(:job_data)
              params[:active_job] = job.payload_object.job_data
              job_class = job.payload_object.job_data['job_class']
            end

            action = job_class || job.payload_object.class.name

            ::Airbrake.notify(exception, params) do |notice|
              notice[:context][:component] = 'delayed_job'
              notice[:context][:action] = action
            end

            ::Airbrake.notify_queue(
              queue: action,
              error_count: 1,
              timing: 0.01,
            )

            raise exception
          else
            ::Airbrake.notify_queue(
              queue: job_class || job.payload_object.class.name,
              error_count: 0,
              timing: timing,
            )
          end
        end
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end

if RUBY_ENGINE == 'jruby' && defined?(Delayed::Backend::ActiveRecord::Job)
  # Workaround against JRuby bug:
  # https://github.com/jruby/jruby/issues/3338
  # rubocop:disable Style/ClassAndModuleChildren
  class Delayed::Backend::ActiveRecord::Job
    alias old_to_ary to_ary

    def to_ary
      old_to_ary || [self]
    end
  end
  # rubocop:enable Style/ClassAndModuleChildren
end

Delayed::Worker.plugins << Delayed::Plugins::Airbrake
