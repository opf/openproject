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

require Rails.root.join("db/migrate/migration_utils/migration_squasher").to_s
# This migration aggregates the migrations detailed in MIGRATION_FILES
class ToV710AggregatedBacklogsMigrations < ActiveRecord::Migration[5.1]
  MIGRATION_FILES = <<-MIGRATIONS
    20111014073606_aggregated_backlogs_migrations.rb
    20130625094113_add_backlogs_column_to_work_package.rb
    20130916094370_legacy_issues_backlogs_data_to_work_packages.rb
    20130919092624_add_backlog_columns_to_work_package_journal.rb
    20131001132542_rename_issue_status_to_status.rb
  MIGRATIONS

  def up
    Migration::MigrationSquasher.squash(migrations) do
      create_table "version_settings", id: :integer do |t|
        t.integer "project_id"
        t.integer "version_id"
        t.integer "display"
        t.datetime "created_at", null: false
        t.datetime "updated_at", null: false
      end
      add_index "version_settings", ["project_id", "version_id"], name: "index_version_settings_on_project_id_and_version_id"

      create_table "done_statuses_for_project", id: false do |t|
        t.integer "project_id"
        t.integer "status_id"
      end

      add_column :work_packages, :position, :integer
      add_column :work_packages, :story_points, :integer
      add_column :work_packages, :remaining_hours, :float

      add_column :work_package_journals, :story_points, :integer
      add_column :work_package_journals, :remaining_hours, :float

      add_index :work_package_journals,
                %i[fixed_version_id
                   status_id
                   project_id
                   type_id],
                name: "work_package_journal_on_burndown_attributes"
    end
  end

  def down
    drop_table "version_settings"
    drop_table "done_statuses_for_project"

    remove_column :work_packages, :position
    remove_column :work_packages, :story_points
    remove_column :work_packages, :remaining_hours

    remove_column :work_package_journals, :story_points
    remove_column :work_package_journals, :remaining_hours

    remove_index :work_package_journals,
                 name: "work_package_journal_on_burndown_attributes"
  end

  private

  def migrations
    MIGRATION_FILES.split.map do |m|
      m.gsub(/_.*\z/, "")
    end
  end
end
