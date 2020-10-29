module WithAdvisoryLock
  class DatabaseAdapterSupport
    # Caches nested lock support by MySQL reported version
    @@mysql_nl_cache       = {}
    @@mysql_nl_cache_mutex = Mutex.new

    def initialize(connection)
      @connection = connection
      @sym_name   = connection.adapter_name.downcase.to_sym
    end

    def mysql?
      %i[mysql mysql2].include? @sym_name
    end

    # Nested lock support for MySQL was introduced in 5.7.5
    # Checking by version number is complicated by MySQL compatible DBs (like MariaDB) having their own versioning schemes
    # Therefore, we check for nested lock support by simply trying a nested lock, then testing and caching the outcome
    def mysql_nested_lock_support?
      return false unless mysql?

      # We select the MySQL version this way and cache on it, as MySQL will report versions like "5.7.5", and MariaDB will
      # report versions like "10.3.8-MariaDB", which allow us to cache on features without introducing problems.
      version = @connection.select_value("SELECT version()")

      @@mysql_nl_cache_mutex.synchronize do
        return @@mysql_nl_cache[version] if @@mysql_nl_cache.keys.include?(version)

        lock_1 = "\"nested-test-1-#{SecureRandom.hex}\""
        lock_2 = "\"nested-test-2-#{SecureRandom.hex}\""

        get_1  = @connection.select_value("SELECT GET_LOCK(#{lock_1}, 0) AS t#{SecureRandom.hex}")
        get_2  = @connection.select_value("SELECT GET_LOCK(#{lock_2}, 0) AS t#{SecureRandom.hex}")

        # Both locks should succeed in old and new MySQL versions with "1"
        raise RuntimeError, "Unexpected nested lock acquire result #{get_1}, #{get_2}" unless [get_1, get_2] == [1, 1]

        release_1 = @connection.select_value("SELECT RELEASE_LOCK(#{lock_1}) AS t#{SecureRandom.hex}")
        release_2 = @connection.select_value("SELECT RELEASE_LOCK(#{lock_2}) AS t#{SecureRandom.hex}")

        # In MySQL <  5.7.5 release_1 will return  nil (not currently locked) and release_2 will return 1 (successfully unlocked)
        # In MySQL >= 5.7.5 release_1 and release_2 will return 1 (both successfully unlocked)
        # See https://dev.mysql.com/doc/refman/5.7/en/miscellaneous-functions.html#function_get-lock for more
        @@mysql_nl_cache[version] = case [release_1, release_2]
                                    when [1, 1]
                                      true
                                    when [nil, 1]
                                      false
                                    else
                                      raise RuntimeError, "Unexpected nested lock release result #{release_1}, #{release_2}"
                                    end
      end
    end

    def postgresql?
      %i[postgresql empostgresql postgis].include? @sym_name
    end

    def sqlite?
      :sqlite3 == @sym_name
    end
  end
end
