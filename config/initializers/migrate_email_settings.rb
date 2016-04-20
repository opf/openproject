OpenProject::Application.configure do
  config.after_initialize do
    # settings table may not exist when you run db:migrate at installation
    # time, so just ignore this block when that happens.
    if Setting.settings_table_exists_yet? && !Setting.email_delivery_migrated?
      Rails.logger.info "Migrating existing email settings to the settings table..."
      OpenProject::Configuration.migrate_mailer_configuration!
    end

    OpenProject::Configuration.reload_mailer_configuration!
  end
end
