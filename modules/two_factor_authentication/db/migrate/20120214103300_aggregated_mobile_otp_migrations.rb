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
require Rails.root.join("db/migrate/migration_utils/setting_renamer").to_s
require "open_project/plugins/migration_mapping"

# This migration aggregates the migrations detailed in MIGRATION_FILES
class AggregatedMobileOtpMigrations < ActiveRecord::Migration[5.0]
  MIGRATION_FILES = <<-MIGRATIONS.freeze
    001_add_user_phone.rb
    002_create_extended_tokens.rb
    003_remove_user_phone.rb
    004_add_user_verified_phone_unverified_phone.rb
  MIGRATIONS

  OLD_PLUGIN_NAME = "redmine_two_factor_authentication_authentication".freeze

  def up
    migration_names = OpenProject::Plugins::MigrationMapping.migration_files_to_migration_names(MIGRATION_FILES, OLD_PLUGIN_NAME)
    Migration::MigrationSquasher.squash(migration_names) do
      add_column :users, :verified_phone, :string
      add_column :users, :unverified_phone, :string
      User.reset_column_information
    end
    Migration::MigrationUtils::SettingRenamer.rename("plugin_redmine_two_factor_authentication_authentication",
                                                     "plugin_openproject_two_factor_authentication")
  end

  def down
    remove_column :users, :verified_phone
    remove_column :users, :unverified_phone
    User.reset_column_information
  end
end
