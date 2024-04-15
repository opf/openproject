Rails.application.configure do
  config.after_initialize do
    next if Rails.env.test?

    # Avoid running this on migrations or when the database is incomplete
    next if OpenProject::Database.migrations_pending?

    slow_sql_threshold = OpenProject::Configuration.sql_slow_query_threshold.to_i
    next if slow_sql_threshold == 0

    ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, start, finish, _id, data|
      # Skip transaction that may be blocked
      next if data[:sql].match?(/BEGIN|COMMIT/)

      # Skip smaller durations
      duration = ((finish - start) * 1000).round(4)
      next if duration <= slow_sql_threshold

      payload = {
        duration:,
        time: start.iso8601,
        cached: !!data[:cache],
        sql: data[:sql]
      }

      sql_log_string = data[:sql].strip.gsub(/(^(\s+)?$\n)/, "")
      OpenProject.logger.warn "Encountered slow SQL (#{payload[:duration]} ms): #{sql_log_string}",
                              payload:,
                              # Hash of the query for reference/fingerprinting
                              reference: Digest::SHA1.hexdigest(data[:sql])
    rescue StandardError => e
      OpenProject.logger.error "Failed to record slow SQL query: #{e}"
    end
  end
end
