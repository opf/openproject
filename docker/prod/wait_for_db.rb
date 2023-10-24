require 'timeout'

timeout = (ENV['WAIT_FOR_DB_TIMEOUT_SECONDS'] || 120).to_i
wait_for_migrations = ENV.fetch('WAIT_FOR_MIGRATIONS', 'true').downcase == 'true'

Timeout::timeout(timeout) do
  loop do
    puts "[#{DateTime.now}] waiting for db to be ready #{wait_for_migrations ? 'and migrated' : ''}"
    sleep 4

    begin
      if wait_for_migrations
        ActiveRecord::Migration.check_pending!
      else
        ActiveRecord::Base.establish_connection
        ActiveRecord::Base.connection # Calls connection object
        raise "Connection to DB failed" unless ActiveRecord::Base.connected?
      end

      puts "[#{DateTime.now}] db ready"
      exit 0
    rescue StandardError => e
      puts "[#{DateTime.now}] not ready yet: #{e.message}"
    end
  end
end
