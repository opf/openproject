Rails.application.config.after_initialize do
  # Use timestampz to create new timestamp columns, so that we get WITH TIME ZONE support
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = :timestamptz
end
