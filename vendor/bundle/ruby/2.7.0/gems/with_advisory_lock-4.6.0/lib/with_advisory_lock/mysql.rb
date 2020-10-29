module WithAdvisoryLock
  # MySQL > 5.7.5 supports nested locks
  class MySQL < Base
    # See https://dev.mysql.com/doc/refman/5.7/en/miscellaneous-functions.html#function_get-lock
    def try_lock
      raise ArgumentError, 'shared locks are not supported on MySQL' if shared
      if transaction
        raise ArgumentError, 'transaction level locks are not supported on MySQL'
      end
      execute_successful?("GET_LOCK(#{quoted_lock_str}, 0)")
    end

    def release_lock
      execute_successful?("RELEASE_LOCK(#{quoted_lock_str})")
    end

    def execute_successful?(mysql_function)
      sql = "SELECT #{mysql_function} AS #{unique_column_name}"
      connection.select_value(sql).to_i > 0
    end

    # MySQL wants a string as the lock key.
    def quoted_lock_str
      connection.quote(lock_str)
    end
  end
end
