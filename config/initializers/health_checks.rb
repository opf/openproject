require 'ok_computer/ok_computer_controller'

class DelayedJobNeverRanCheck < OkComputer::Check
  attr_reader :threshold

  def initialize(minute_threshold)
    @threshold = minute_threshold.to_i
  end

  def check
    never_ran = Delayed::Job.where('run_at < ?', threshold.minutes.ago).count

    if never_ran.zero?
      mark_message "All previous jobs have completed within the past #{threshold} minutes."
    else
      mark_failure
      mark_message "#{never_ran} jobs waiting to be executed for more than #{threshold} minutes"
    end
  end
end

# Register delayed_job backed up test
dj_max = OpenProject::Configuration.health_checks_jobs_queue_count_threshold
OkComputer::Registry.register "delayed_jobs_backed_up",
                              OkComputer::DelayedJobBackedUpCheck.new(0, dj_max)

dj_never_ran_max = OpenProject::Configuration.health_checks_jobs_never_ran_minutes_ago
OkComputer::Registry.register "delayed_jobs_never_ran",
                              DelayedJobNeverRanCheck.new(dj_never_ran_max)

# Make dj backed up optional due to bursts
OkComputer.make_optional %w(delayed_jobs_backed_up)

# Register web worker check for web + database
OkComputer::CheckCollection.new('web').tap do |collection|
  collection.register :default, OkComputer::Registry.fetch('default')
  collection.register :database, OkComputer::Registry.fetch('database')
  OkComputer::Registry.default_collection.register 'web', collection
end

# Register full check for web + database + dj worker
OkComputer::CheckCollection.new('full').tap do |collection|
  collection.register :default, OkComputer::Registry.fetch('default')
  collection.register :database, OkComputer::Registry.fetch('database')
  collection.register :mail, OkComputer::ActionMailerCheck.new
  collection.register :delayed_jobs_backed_up, OkComputer::Registry.fetch('delayed_jobs_backed_up')
  collection.register :delayed_jobs_never_ran, OkComputer::Registry.fetch('delayed_jobs_never_ran')
  OkComputer::Registry.default_collection.register 'full', collection
end

# Check if authentication required
authentication_password = OpenProject::Configuration.health_checks_authentication_password
if authentication_password.present?
  OkComputer.require_authentication('health_checks', authentication_password)
end
