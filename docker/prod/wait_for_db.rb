require "timeout"

timeout = (ENV["WAIT_FOR_DB_TIMEOUT_SECONDS"] || 120).to_i

Timeout::timeout(timeout) do
  loop do
    puts "[#{DateTime.now}] waiting for db to be ready and migrated"
    sleep 4

    begin
      ActiveRecord::Migration.check_pending!

      puts "[#{DateTime.now}] db ready"
      exit 0
    rescue StandardError => e
      puts "[#{DateTime.now}] not ready yet: #{e.message}"
    end
  end
end
