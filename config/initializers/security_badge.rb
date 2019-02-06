OpenProject::Application.configure do
  config.after_initialize do
    if Setting.settings_table_exists_yet?
      Setting.installation_uuid ||= SecureRandom.uuid
    end
  end
end
