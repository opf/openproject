OpenProject::Application.configure do
  config.after_initialize do
    ActiveSupport::Notifications.subscribe('openproject_grape_logger') do |_, _, _, _, payload|
      time = payload.delete :time
      attributes = {
        duration: time[:total],
        db: time[:db],
        view: time[:view]
      }.merge(payload)

      string = OpenProject::Logging.formatter.call(attributes)
      Rails.logger.info string
    end
  end
end
