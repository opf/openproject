# Use timestampz to create new timestamp columns, so that we get WITH TIME ZONE support
if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.datetime_type = :timestamptz
end
