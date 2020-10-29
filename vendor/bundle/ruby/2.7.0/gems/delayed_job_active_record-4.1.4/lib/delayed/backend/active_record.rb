# frozen_string_literal: true

require "active_record/version"
module Delayed
  module Backend
    module ActiveRecord
      class Configuration
        attr_reader :reserve_sql_strategy

        def initialize
          self.reserve_sql_strategy = :optimized_sql
        end

        def reserve_sql_strategy=(val)
          if !(val == :optimized_sql || val == :default_sql)
            raise ArgumentError, "allowed values are :optimized_sql or :default_sql"
          end

          @reserve_sql_strategy = val
        end
      end

      def self.configuration
        @configuration ||= Configuration.new
      end

      def self.configure
        yield(configuration)
      end

      # A job object that is persisted to the database.
      # Contains the work object as a YAML field.
      class Job < ::ActiveRecord::Base
        include Delayed::Backend::Base

        if ::ActiveRecord::VERSION::MAJOR < 4 || defined?(::ActiveRecord::MassAssignmentSecurity)
          attr_accessible :priority, :run_at, :queue, :payload_object,
                          :failed_at, :locked_at, :locked_by, :handler
        end

        scope :by_priority, lambda { order("priority ASC, run_at ASC") }
        scope :min_priority, lambda { where("priority >= ?", Worker.min_priority) if Worker.min_priority }
        scope :max_priority, lambda { where("priority <= ?", Worker.max_priority) if Worker.max_priority }
        scope :for_queues, lambda { |queues = Worker.queues| where(queue: queues) if Array(queues).any? }

        before_save :set_default_run_at

        def self.set_delayed_job_table_name
          delayed_job_table_name = "#{::ActiveRecord::Base.table_name_prefix}delayed_jobs"
          self.table_name = delayed_job_table_name
        end

        set_delayed_job_table_name

        def self.ready_to_run(worker_name, max_run_time)
          where(
            "(run_at <= ? AND (locked_at IS NULL OR locked_at < ?) OR locked_by = ?) AND failed_at IS NULL",
            db_time_now,
            db_time_now - max_run_time,
            worker_name
          )
        end

        def self.before_fork
          ::ActiveRecord::Base.clear_all_connections!
        end

        def self.after_fork
          ::ActiveRecord::Base.establish_connection
        end

        # When a worker is exiting, make sure we don't have any locked jobs.
        def self.clear_locks!(worker_name)
          where(locked_by: worker_name).update_all(locked_by: nil, locked_at: nil)
        end

        def self.reserve(worker, max_run_time = Worker.max_run_time)
          ready_scope =
            ready_to_run(worker.name, max_run_time)
            .min_priority
            .max_priority
            .for_queues
            .by_priority

          reserve_with_scope(ready_scope, worker, db_time_now)
        end

        def self.reserve_with_scope(ready_scope, worker, now)
          case Delayed::Backend::ActiveRecord.configuration.reserve_sql_strategy
          # Optimizations for faster lookups on some common databases
          when :optimized_sql
            reserve_with_scope_using_optimized_sql(ready_scope, worker, now)
          # Slower but in some cases more unproblematic strategy to lookup records
          # See https://github.com/collectiveidea/delayed_job_active_record/pull/89 for more details.
          when :default_sql
            reserve_with_scope_using_default_sql(ready_scope, worker, now)
          end
        end

        def self.reserve_with_scope_using_optimized_sql(ready_scope, worker, now)
          case connection.adapter_name
          when "PostgreSQL", "PostGIS"
            reserve_with_scope_using_optimized_postgres(ready_scope, worker, now)
          when "MySQL", "Mysql2"
            reserve_with_scope_using_optimized_mysql(ready_scope, worker, now)
          when "MSSQL", "Teradata"
            reserve_with_scope_using_optimized_mssql(ready_scope, worker, now)
          # Fallback for unknown / other DBMS
          else
            reserve_with_scope_using_default_sql(ready_scope, worker, now)
          end
        end

        def self.reserve_with_scope_using_default_sql(ready_scope, worker, now)
          # This is our old fashion, tried and true, but slower lookup
          ready_scope.limit(worker.read_ahead).detect do |job|
            count = ready_scope.where(id: job.id).update_all(locked_at: now, locked_by: worker.name)
            count == 1 && job.reload
          end
        end

        def self.reserve_with_scope_using_optimized_postgres(ready_scope, worker, now)
          # Custom SQL required for PostgreSQL because postgres does not support UPDATE...LIMIT
          # This locks the single record 'FOR UPDATE' in the subquery
          # http://www.postgresql.org/docs/9.0/static/sql-select.html#SQL-FOR-UPDATE-SHARE
          # Note: active_record would attempt to generate UPDATE...LIMIT like
          # SQL for Postgres if we use a .limit() filter, but it would not
          # use 'FOR UPDATE' and we would have many locking conflicts
          quoted_name = connection.quote_table_name(table_name)
          subquery    = ready_scope.limit(1).lock(true).select("id").to_sql
          sql         = "UPDATE #{quoted_name} SET locked_at = ?, locked_by = ? WHERE id IN (#{subquery}) RETURNING *"
          reserved    = find_by_sql([sql, now, worker.name])
          reserved[0]
        end

        def self.reserve_with_scope_using_optimized_mysql(ready_scope, worker, now)
          # Removing the millisecond precision from now(time object)
          # MySQL 5.6.4 onwards millisecond precision exists, but the
          # datetime object created doesn't have precision, so discarded
          # while updating. But during the where clause, for mysql(>=5.6.4),
          # it queries with precision as well. So removing the precision
          now = now.change(usec: 0)
          # This works on MySQL and possibly some other DBs that support
          # UPDATE...LIMIT. It uses separate queries to lock and return the job
          count = ready_scope.limit(1).update_all(locked_at: now, locked_by: worker.name)
          return nil if count == 0

          where(locked_at: now, locked_by: worker.name, failed_at: nil).first
        end

        def self.reserve_with_scope_using_optimized_mssql(ready_scope, worker, now)
          # The MSSQL driver doesn't generate a limit clause when update_all
          # is called directly
          subsubquery_sql = ready_scope.limit(1).to_sql
          # select("id") doesn't generate a subquery, so force a subquery
          subquery_sql = "SELECT id FROM (#{subsubquery_sql}) AS x"
          quoted_table_name = connection.quote_table_name(table_name)
          sql = "UPDATE #{quoted_table_name} SET locked_at = ?, locked_by = ? WHERE id IN (#{subquery_sql})"
          count = connection.execute(sanitize_sql([sql, now, worker.name]))
          return nil if count == 0

          # MSSQL JDBC doesn't support OUTPUT INSERTED.* for returning a result set, so query locked row
          where(locked_at: now, locked_by: worker.name, failed_at: nil).first
        end

        # Get the current time (GMT or local depending on DB)
        # Note: This does not ping the DB to get the time, so all your clients
        # must have syncronized clocks.
        def self.db_time_now
          if Time.zone
            Time.zone.now
          elsif ::ActiveRecord::Base.default_timezone == :utc
            Time.now.utc
          else
            Time.now # rubocop:disable Rails/TimeZone
          end
        end

        def reload(*args)
          reset
          super
        end
      end
    end
  end
end
