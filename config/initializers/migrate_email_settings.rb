OpenProject::Application.configure do
  config.after_initialize do
    unless Setting.email_delivery_migrated?
      Rails.logger.info "Migrating existing email settings to the settings table..."
      OpenProject::Configuration.migrate_mailer_configuration!
    end

    OpenProject::Configuration.reload_mailer_configuration!
  end
end
