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

# This migration aggregates the migrations passed in migrations into one given as a block
# heredoc
module Migration
  class MigrationSquasher
    class IncompleteMigrationsError < ::StandardError
    end

    # define all the following methods as class methods
    class << self
      def squash(aggregated_versions, minimum_version)
        intersection = aggregated_versions & all_versions

        if intersection == []

          # No migrations that this migration aggregates have already been
          # applied. In this case, run the aggregated migration passed as a block
          yield

        elsif intersection == aggregated_versions

          # All migrations that this migration aggregates have already
          # been applied. In this case, remove the information about those
          # migrations from the schema_migrations table and we're done.
          ActiveRecord::Base.connection.execute <<-SQL.squish + (intersection.map { |version| <<-CONDITIONS }).join(" OR ")
            DELETE FROM
              #{quoted_schema_migrations_table_name}
            WHERE
          SQL
            #{version_column_for_comparison} = #{quote_value(version)}
          CONDITIONS

        else

          missing = aggregated_versions - intersection

          # Only a part of the migrations that this migration aggregates
          # have already been applied. In this case, fail miserably.
          raise IncompleteMigrationsError,
                <<~MESSAGE.squish
                  It appears you are migrating from an incompatible version.
                  Your database has only some migrations to be squashed.

                  OpenProject only supports migrating from one major version to the next.
                  Please update your installation to OpenProject v#{minimum_version} (any minor or patch level) first.
                  After the migrations in that version ran successfully, reinstall this OpenProject version and rerun the migrations.

                  The following migrations are missing: #{missing}
                MESSAGE
        end
      end

      private

      def all_versions
        table = Arel::Table.new(schema_migrations_table_name)
        ActiveRecord::Base.connection.select_values(table.project(table["version"]))
      end

      def schema_migrations_table_name
        ActiveRecord::Base.connection.pool.schema_migration.table_name
      end

      def quoted_schema_migrations_table_name
        ActiveRecord::Base.connection.quote_table_name(schema_migrations_table_name)
      end

      def quoted_version_column_name
        ActiveRecord::Base.connection.quote_table_name("version")
      end

      def version_column_for_comparison
        "#{quoted_schema_migrations_table_name}.#{quoted_version_column_name}"
      end

      def quote_value(s)
        ActiveRecord::Base.connection.quote(s)
      end
    end
  end
end
