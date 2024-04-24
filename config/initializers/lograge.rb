Rails.application.configure do
  next unless OpenProject::Logging.lograge_enabled?

  config.lograge.enabled = true
  config.lograge.keep_original_rails_log = Rails.env.development?
  config.lograge.formatter = OpenProject::Logging.formatter
  config.lograge.base_controller_class = %w[ActionController::Base]

  # Add custom data to event payload
  config.lograge.custom_payload do |controller|
    OpenProject::Logging.extend_payload!({}, { controller: })
  end
end
