Rails.application.configure do
  config.after_initialize do
    OkComputer::Registry.register "worker", OpenProject::HealthChecks::GoodJobCheck.new
    OkComputer::Registry.register "worker_backed_up", OpenProject::HealthChecks::GoodJobBackedUpCheck.new

    OkComputer::Registry.register "puma", OpenProject::HealthChecks::PumaCheck.new

    # Make dj backed up optional due to bursts
    OkComputer.make_optional %w(worker_backed_up puma)

    # Register web worker check for web + database
    OkComputer::CheckCollection.new("web").tap do |collection|
      collection.register :default, OkComputer::Registry.fetch("default")
      collection.register :database, OkComputer::Registry.fetch("database")
      OkComputer::Registry.default_collection.register "web", collection
    end

    # Register full check for web + database + dj worker
    OkComputer::CheckCollection.new("full").tap do |collection|
      collection.register :default, OkComputer::Registry.fetch("default")
      collection.register :database, OkComputer::Registry.fetch("database")
      collection.register :mail, OpenProject::HealthChecks::SmtpCheck.new
      collection.register :worker, OkComputer::Registry.fetch("worker")
      collection.register :worker_backed_up, OkComputer::Registry.fetch("worker_backed_up")
      collection.register :puma, OkComputer::Registry.fetch("puma")
      OkComputer::Registry.default_collection.register "full", collection
    end

    # Check if authentication required
    authentication_password = OpenProject::Configuration.health_checks_authentication_password
    if authentication_password.present?
      OkComputer.require_authentication("health_checks", authentication_password)
    end
  end
end
