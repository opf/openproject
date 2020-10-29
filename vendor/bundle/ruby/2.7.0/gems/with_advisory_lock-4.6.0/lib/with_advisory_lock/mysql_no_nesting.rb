module WithAdvisoryLock
  # For MySQL < 5.7.5 that does not support nested locks
  class MySQLNoNesting < MySQL
    # See http://dev.mysql.com/doc/refman/5.0/en/miscellaneous-functions.html#function_get-lock
    def try_lock
      unless lock_stack.empty?
        raise NestedAdvisoryLockError.new(
          "MySQL < 5.7.5 doesn't support nested Advisory Locks",
          lock_stack.dup
        )
      end
      super
    end

    # MySQL doesn't support nested locks:
    def already_locked?
      lock_stack.last == lock_stack_item
    end
  end
end
