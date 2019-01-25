Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.base_controller_class = %w[ActionController::Base]

  # Add custom data to event payload
  config.lograge.custom_payload do |controller|
    ::OpenProject::Logging::LogDelegator.controller_payload_hash controller
  end
end
