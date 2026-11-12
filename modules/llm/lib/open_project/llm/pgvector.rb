# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Llm
    # pgvector is optional while installations catch up on installing it.
    #
    # Migrations that need it live in db/migrate_optional/pgvector, which is only added to
    # the migration paths once the extension is installed or can be created. Until then they are
    # neither run nor reported as pending, and a later db:migrate picks them up.
    # The extension itself is created by a migration in that path, so installation goes
    # through the regular migration pipeline instead of a single connection.
    # Making pgvector mandatory means moving them into db/migrate and deleting this.
    module Pgvector
      EXTENSION = "vector"
      DOCS_URL = "https://www.openproject.org/docs/installation-and-operations/system-requirements/#pgvector"

      Failure = Data.define(:reason, :detail)

      module TypeRegistration
        TYPES = %w[halfvec].freeze

        def initialize_type_map(type_map)
          super

          specialized_string = ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID::SpecializedString
          TYPES.each { |type_name| type_map.register_type type_name, specialized_string.new(type_name.to_sym) }
        end
      end

      class << self
        def register_active_record_type
          ActiveSupport.on_load(:active_record_postgresqladapter) do
            singleton_class.prepend(TypeRegistration)
          end
        end

        def available?
          return @available if defined?(@available)

          @available = extension_installed? && migrations_applied?
        end

        def extension_available?
          catalog_contains?("SELECT 1 FROM pg_available_extensions WHERE name = '#{EXTENSION}'")
        end

        def extension_installed?
          catalog_contains?("SELECT 1 FROM pg_extension WHERE extname = '#{EXTENSION}'")
        end

        def migrations_applied?
          !migration_context.needs_migration?
        end

        def include_migrations_path_if_installed!
          include_migrations_path! if extension_installed?
        rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError
          # No database yet, e.g. before db:create. db:migrate decides again.
        end

        def include_migrations_path_if_installable!
          failure = check_if_installable
          include_migrations_path! if failure.nil?
          failure
        end

        # The extension lives in pg_catalog, so once installed it is shared by every schema
        # and need not be checked for installability again.
        def migrate_pending_if_installable!
          if extension_installed?
            include_migrations_path!
          elsif include_migrations_path_if_installable!
            return
          end

          migration_context.migrate
        rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::NoDatabaseError
          nil
        end

        def include_migrations_path!
          app_paths = Rails.application.config.paths["db/migrate"]
          return if app_paths.to_a.include?(migrations_path)

          app_paths << migrations_path
          ActiveRecord::Tasks::DatabaseTasks.migrations_paths = app_paths.to_a
          ActiveRecord::Migrator.migrations_paths = app_paths.to_a
        end

        def warning(failure)
          <<~MESSAGE

            ---------------------------------------------------
            PGVECTOR NOT AVAILABLE
            #{failure_explanation(failure)}

            Features depending on pgvector are disabled.
            Once the extension can be created, run the migrations again
            (e.g. `openproject configure` or `rake db:migrate`) to set them up.

            Read more at #{DOCS_URL}
            ---------------------------------------------------

          MESSAGE
        end

        def migrations_path
          Engine.root.join("db/migrate_optional/pgvector").to_s
        end

        private

        def check_if_installable
          return Failure.new(reason: :unavailable, detail: nil) unless extension_available?

          try_creating_extension
        end

        # Managed services such as AWS RDS grant extensions through their own roles and allow lists,
        # which the catalog does not reflect. Only actually creating the extension tells.
        def try_creating_extension
          connection.transaction(requires_new: true) do
            connection.execute("CREATE EXTENSION IF NOT EXISTS #{EXTENSION} WITH SCHEMA pg_catalog")
            raise ActiveRecord::Rollback
          end

          nil
        rescue ActiveRecord::StatementInvalid => e
          Failure.new(reason: creation_failure_reason(e.cause), detail: e.message)
        end

        def creation_failure_reason(error)
          case error
          when PG::InsufficientPrivilege then :insufficient_privilege
          when PG::ReadOnlySqlTransaction then :read_only
          else :error
          end
        end

        def failure_explanation(failure)
          case failure.reason
          when :unavailable
            <<~TEXT.chomp
              The pgvector extension is not installed on the PostgreSQL server.
              See https://github.com/pgvector/pgvector#installation for installation instructions.
            TEXT
          when :insufficient_privilege
            <<~TEXT.chomp
              The database user is not allowed to create the pgvector extension.
            TEXT
          when :read_only
            "The database connection is read-only."
          else
            "Creating the pgvector extension failed: #{failure.detail}"
          end
        end

        def catalog_contains?(sql)
          connection.select_value(sql).present?
        end

        def migration_context
          pool = ActiveRecord::Base.connection_pool
          ActiveRecord::MigrationContext.new([migrations_path], pool.schema_migration, pool.internal_metadata)
        end

        def connection
          ActiveRecord::Base.connection
        end
      end
    end
  end
end
