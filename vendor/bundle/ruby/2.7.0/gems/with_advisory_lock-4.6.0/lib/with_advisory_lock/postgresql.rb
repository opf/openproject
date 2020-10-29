module WithAdvisoryLock
  class PostgreSQL < Base
    # See http://www.postgresql.org/docs/9.1/static/functions-admin.html#FUNCTIONS-ADVISORY-LOCKS
    def try_lock
      pg_function = "pg_try_advisory#{transaction ? '_xact' : ''}_lock#{shared ? '_shared' : ''}"
      execute_successful?(pg_function)
    end

    def release_lock
      return if transaction
      pg_function = "pg_advisory_unlock#{shared ? '_shared' : ''}"
      execute_successful?(pg_function)
    rescue ActiveRecord::StatementInvalid => e
      raise unless e.message =~ / ERROR: +current transaction is aborted,/
      begin
        connection.rollback_db_transaction
        execute_successful?(pg_function)
      ensure
        connection.begin_db_transaction
      end
    end

    def execute_successful?(pg_function)
      comment = lock_name.gsub(/(\/\*)|(\*\/)/, '--')
      sql = "SELECT #{pg_function}(#{lock_keys.join(',')}) AS #{unique_column_name} /* #{comment} */"
      result = connection.select_value(sql)
      # MRI returns 't', jruby returns true. YAY!
      (result == 't' || result == true)
    end

    # PostgreSQL wants 2 32bit integers as the lock key.
    def lock_keys
      @lock_keys ||= begin
        [stable_hashcode(lock_name), ENV['WITH_ADVISORY_LOCK_PREFIX']].map do |ea|
          # pg advisory args must be 31 bit ints
          ea.to_i & 0x7fffffff
        end
      end
    end
  end
end
