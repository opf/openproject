require Rails.root.join("db","migrate","migration_utils","migration_squasher").to_s
require Rails.root.join("db","migrate","migration_utils","setting_renamer").to_s
require 'open_project/plugins/migration_mapping'
# This migration aggregates the migrations detailed in MIGRATION_FILES
class AggregatedMobileOtpMigrations < ActiveRecord::Migration

  MIGRATION_FILES = <<-MIGRATIONS
    001_add_user_phone.rb
    002_create_extended_tokens.rb
    003_remove_user_phone.rb
    004_add_user_verified_phone_unverified_phone.rb
  MIGRATIONS

  OLD_PLUGIN_NAME = "redmine_two_factor_authentication_authentication"

  def up
    migration_names = OpenProject::Plugins::MigrationMapping.migration_files_to_migration_names(MIGRATION_FILES, OLD_PLUGIN_NAME)
    Migration::MigrationSquasher.squash(migration_names) do
      add_column :users, :verified_phone, :string
      add_column :users, :unverified_phone, :string
      User.reset_column_information
    end
    Migration::SettingRenamer.rename("plugin_redmine_two_factor_authentication_authentication","plugin_openproject_two_factor_authentication")
  end

  def down
    remove_column :users, :verified_phone
    remove_column :users, :unverified_phone
    User.reset_column_information
  end
end
