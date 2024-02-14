Rails.application.configure do
  config.after_initialize do
    ActiveSupport::Notifications.subscribe('openproject_grape_logger') do |_, _, _, _, payload|
      time = payload[:time]
      attributes = {
        duration: time[:total],
        db: time[:db],
        view: time[:view]
      }.merge(payload.except(:time))

      extended = OpenProject::Logging.extend_payload!(attributes, {})
      Rails.logger.info OpenProject::Logging.formatter.call(extended)
    end
  end
end
