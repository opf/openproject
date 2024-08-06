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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

Dir["#{Rails.root.join('db/migrate/tables/*.rb')}"].each { |file| require file }
Dir["#{Rails.root.join('db/migrate/aggregated/*.rb')}"].each { |file| require file }

# This migration aggregates a set of former migrations
class ToV710AggregatedMigrations < ActiveRecord::Migration[5.1]
  class IncompleteMigrationsError < ::StandardError
  end

  @tables = [
    Tables::WorkPackages,
    Tables::Users,
    Tables::GroupUsers,
    Tables::Categories,
    Tables::Relations,
    Tables::Statuses,
    Tables::Projects,
    Tables::TimeEntries,
    Tables::Sessions,
    Tables::Announcements,
    Tables::Attachments,
    Tables::AuthSources,
    Tables::Boards,
    Tables::Messages,
    Tables::CustomFields,
    Tables::CustomFieldsProjects,
    Tables::CustomFieldsTypes,
    Tables::CustomOptions,
    Tables::CustomValues,
    Tables::Changesets,
    Tables::ChangesetsWorkPackages,
    Tables::Journals,
    Tables::WorkPackageJournals,
    Tables::MessageJournals,
    Tables::NewsJournals,
    Tables::WikiContentJournals,
    Tables::TimeEntryJournals,
    Tables::ChangesetJournals,
    Tables::AttachmentJournals,
    Tables::AttachableJournals,
    Tables::CustomizableJournals,
    Tables::Comments,
    Tables::Changes,
    Tables::Repositories,
    Tables::Enumerations,
    Tables::Roles,
    Tables::RolePermissions,
    Tables::MemberRoles,
    Tables::Members,
    Tables::News,
    Tables::ProjectTypes,
    Tables::PlanningElementTypeColors,
    Tables::Reportings,
    Tables::AvailableProjectStatuses,
    Tables::ProjectAssociations,
    Tables::Timelines,
    Tables::ProjectsTypes,
    Tables::Queries,
    Tables::Types,
    Tables::Settings,
    Tables::Tokens,
    Tables::UserPreferences,
    Tables::UserPasswords,
    Tables::Versions,
    Tables::Watchers,
    Tables::WikiContentVersions,
    Tables::WikiContents,
    Tables::WikiPages,
    Tables::WikiRedirects,
    Tables::Wikis,
    Tables::Workflows,
    Tables::DelayedJobs,
    Tables::MenuItems,
    Tables::CustomStyles,
    Tables::DesignColors,
    Tables::EnterpriseTokens,
    Tables::EnabledModules
  ]

  def self.tables
    @tables
  end

  def up
    raise_on_incomplete_3_0_migrations
    raise_on_incomplete_7_1_migrations

    intersection = aggregated_versions_7_1 & all_versions

    if intersection == aggregated_versions_7_1
      remove_applied_migration_entries(intersection)
    else
      run_aggregated_migrations
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Use OpenProject v7.4 for the down migrations"
  end

  private

  # No migrations that this migration aggregates have already been
  # applied. In this case, run the aggregated migration.
  def run_aggregated_migrations
    create_tables
  end

  # All migrations that this migration aggregates have already
  # been applied. In this case, remove the information about those
  # migrations from the schema_migrations table and we're done.
  def remove_applied_migration_entries(intersection)
    execute <<-SQL + (intersection.map { |version| <<-CONDITIONS }).join(" OR ")
        DELETE FROM
          #{quoted_schema_migrations_table_name}
        WHERE
    SQL
      #{version_column_for_comparison} = #{quote_value(version.to_s)}
    CONDITIONS
  end

  def raise_on_incomplete_3_0_migrations
    raise_on_incomplete_migrations(aggregated_versions_3_0, "v2.4.0", "ChiliProject")
  end

  def raise_on_incomplete_7_1_migrations
    raise_on_incomplete_migrations(aggregated_versions_7_1, "v7.4.0", "OpenProject")
  end

  def raise_on_incomplete_migrations(aggregated_versions, version_number, app_name)
    intersection = aggregated_versions & all_versions

    if !intersection.empty? && intersection != aggregated_versions

      missing = aggregated_versions - intersection

      # Only a part of the migrations that this migration aggregates
      # have already been applied. In this case, fail miserably.
      raise IncompleteMigrationsError, <<-MESSAGE.split("\n").map(&:strip!).join(" ") + "\n"
        It appears you are migrating from an incompatible version of
        #{app_name}. Yourdatabase has only some migrations from #{app_name} <
        #{version_number} Please update your database to the schema of #{app_name}
        #{version_number} and run the OpenProject migrations again. The following
        migrations are missing: #{missing}
      MESSAGE
    end
  end

  def create_tables
    self.class.tables.each do |table|
      table.create(self)
    end
  end

  def aggregated_versions_3_0
    Aggregated::To_3_0.normalized_migrations
  end

  def aggregated_versions_7_1
    Aggregated::To_7_1.normalized_migrations
  end

  def all_versions
    @all_versions ||= ActiveRecord::Base.connection.migration_context.get_all_versions
  end

  def schema_migrations_table_name
    ActiveRecord::Base.connection.schema_migration.table_name
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
