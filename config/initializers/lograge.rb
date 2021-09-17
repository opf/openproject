Rails.application.configure do
  next unless OpenProject::Logging::Lograge.enabled?

  config.lograge.enabled = true
  config.lograge.formatter = OpenProject::Logging::Lograge.formatter_class.new
  config.lograge.base_controller_class = %w[ActionController::Base]

  # Add custom data to event payload
  config.lograge.custom_payload do |controller|
    ::OpenProject::Logging::LogDelegator.controller_payload_hash controller
  end
end
