require Rails.root.join("db","migrate","migration_utils","migration_squasher").to_s
require 'open_project/plugins/migration_mapping'
# This migration aggregates the migrations detailed in MIGRATION_FILES
class AggregatedGlobalRolesMigrations < ActiveRecord::Migration


  MIGRATION_FILES = <<-MIGRATIONS
    001_sti_for_roles.rb
  MIGRATIONS

  OLD_PLUGIN_NAME = "redmine_global_roles"

  def up
    migration_names = OpenProject::Plugins::MigrationMapping.migration_files_to_migration_names(MIGRATION_FILES, OLD_PLUGIN_NAME)
    Migration::MigrationSquasher.squash(migration_names) do
      add_column :roles, :type, :string, :limit => 30, :default => "Role"

      ActiveRecord::Base.connection.execute("UPDATE roles SET type='Role';")

      Role.reset_column_information

      create_table :principal_roles do |t|
        t.column :role_id, :integer, :null => false
        t.column :principal_id, :integer, :null => false
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



