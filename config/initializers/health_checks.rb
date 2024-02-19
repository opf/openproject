require 'ok_computer/ok_computer_controller'

class GoodJobCheck < OkComputer::Check
  def initialize;end

  def check
    count = GoodJob::Process.active.count

    if count.zero?
      mark_failure
      mark_message "No good_job processes are active."
    else
      mark_message "#{count} good_job processes are active."
    end
  end
end

class PumaCheck < OkComputer::Check
  attr_reader :threshold

  def initialize(backlog_threshold)
    @threshold = backlog_threshold.to_i
  end

  def check
    stats = self.stats

    return mark_message "N/A as Puma is not used." if stats.nil?

    if stats[:running] > 0
      mark_message "Puma is running"
    else
      mark_failure
      mark_message "Puma is not running"
    end

    if stats[:backlog] < threshold
      mark_message "Backlog ok"
    else
      mark_failure
      mark_message "Backlog congested"
    end
  end

  def stats
    return nil unless applicable?

    server = Puma::Server.current
    return nil if server.nil?

    {
      backlog: server.backlog || 0,
      running: server.running || 0,
      pool_capacity: server.pool_capacity || 0,
      max_threads: server.max_threads || 0
    }
  end

  def applicable?
    return @applicable unless @applicable.nil?

    @applicable = Object.const_defined?("Puma::Server") && !Puma::Server.current.nil?
  end
end

OkComputer::Registry.register "worker", GoodJobCheck.new

backlog_threshold = OpenProject::Configuration.health_checks_backlog_threshold
OkComputer::Registry.register "puma", PumaCheck.new(backlog_threshold)

# Make dj backed up optional due to bursts
OkComputer.make_optional %w(puma)

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
  collection.register :worker, OkComputer::Registry.fetch('worker')
  collection.register :puma, OkComputer::Registry.fetch('puma')
  OkComputer::Registry.default_collection.register 'full', collection
end

# Check if authentication required
authentication_password = OpenProject::Configuration.health_checks_authentication_password
if authentication_password.present?
  OkComputer.require_authentication('health_checks', authentication_password)
end
