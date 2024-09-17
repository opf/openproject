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
require "open_project/plugins/migration_mapping"
# This migration aggregates the migrations detailed in MIGRATION_FILES
class AggregatedGlobalRolesMigrations < ActiveRecord::Migration[5.0]
  MIGRATION_FILES = <<-MIGRATIONS
    001_sti_for_roles.rb
  MIGRATIONS

  OLD_PLUGIN_NAME = "redmine_global_roles"

  def up
    migration_names = OpenProject::Plugins::MigrationMapping.migration_files_to_migration_names(MIGRATION_FILES, OLD_PLUGIN_NAME)
    Migration::MigrationSquasher.squash(migration_names) do
      add_column :roles, :type, :string, limit: 30, default: "Role"

      ActiveRecord::Base.connection.execute("UPDATE roles SET type='Role';")

      Role.reset_column_information

      create_table :principal_roles do |t|
        t.column :role_id, :integer, null: false
        t.column :principal_id, :integer, null: false
        t.timestamps
      end

      add_index :principal_roles, :role_id
      add_index :principal_roles, :principal_id
    end
  end

  def down
    remove_column :roles, :type
    remove_index :principal_roles, :role_id
    remove_index :principal_roles, :principal_id
    drop_table :principal_roles
    Role.reset_column_information
  end
end
