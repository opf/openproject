# frozen_string_literal: true

# This is not bulletproof, but if this file is executed before a task
# definition, we can grab tasks descriptions and locations.
# See: https://goo.gl/ksn6PE
Rake::TaskManager.record_task_metadata = true

module Rake
  # Redefine +Rake::Task#execute+, so it can report errors to Airbrake.
  class Task
    # Store the original method to use it later.
    alias execute_without_airbrake execute

    # A wrapper around the original +#execute+, that catches all errors and
    # notifies Airbrake.
    #
    # rubocop:disable Lint/RescueException
    def execute(args = nil)
      execute_without_airbrake(args)
    rescue Exception => ex
      notify_airbrake(ex, args)
      raise ex
    end
    # rubocop:enable Lint/RescueException

    private

    def notify_airbrake(exception, args)
      notice = Airbrake.build_notice(exception)
      notice[:context][:component] = 'rake'
      notice[:context][:action] = name
      notice[:params].merge!(
        rake_task: task_info,
        execute_args: args,
        argv: ARGV.join(' '),
      )

      Airbrake.notify_sync(notice)
    end

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
    def task_info
      info = {}

      info[:name] = name
      info[:timestamp] = timestamp.to_s
      info[:investigation] = investigation

      info[:full_comment] = full_comment if full_comment
      info[:arg_names] = arg_names if arg_names.any?
      info[:arg_description] = arg_description if arg_description
      info[:locations] = locations if locations.any?
      info[:sources] = sources if sources.any?

      if prerequisite_tasks.any?
        info[:prerequisite_tasks] = prerequisite_tasks.map do |p|
          p.__send__(:task_info)
        end
      end

      info
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize
  end
end
