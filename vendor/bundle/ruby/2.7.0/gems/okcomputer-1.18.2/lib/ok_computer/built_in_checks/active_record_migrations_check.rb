module OkComputer
  class ActiveRecordMigrationsCheck < Check
    # Public: Check if migrations are pending or not
    def check
      return unsupported unless supported?

      if needs_migration?
        mark_failure
        mark_message "Pending migrations"
      else
        mark_message "NO pending migrations"
      end
    end

    def needs_migration?
      if ActiveRecord::Migrator.respond_to?(:needs_migration?) # Rails <= 5.1
        ActiveRecord::Migrator.needs_migration?
      else # Rails >= 5.2
        ActiveRecord::Base.connection.migration_context.needs_migration?
      end
    end

    def supported?
      ActiveRecord::Migrator.respond_to?(:needs_migration?) ||
        (ActiveRecord::Base.connection.respond_to?(:migration_context) &&
         ActiveRecord::Base.connection.migration_context.respond_to?(:needs_migration?))
    end

    private

    # Private: Fail the check if ActiveRecord cannot check migration status
    def unsupported
      mark_failure
      mark_message "This version of ActiveRecord does not support checking whether migrations are pending"
    end
  end
end
