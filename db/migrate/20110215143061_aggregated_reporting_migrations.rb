require Rails.root.join("db","migrate","migration_utils","migration_squasher").to_s
require 'open_project/plugins/migration_mapping'
# This migration aggregates the migrations detailed in MIGRATION_FILES
class AggregatedReportingMigrations < ActiveRecord::Migration

  MIGRATION_FILES = <<-MIGRATIONS
    20101111150110_adjust_cost_query_layout.rb
    20101124150110_adjust_cost_query_layout_some_more.rb
    20101202142038_change_cost_query_yaml_length.rb
    20101203110501_rename_yamlized_to_serialized.rb
    20110215143010_add_timestamps_to_custom_fields.rb
  MIGRATIONS

  OLD_PLUGIN_NAME = "redmine_reporting"

  def up
    migration_names = OpenProject::Plugins::MigrationMapping.migration_files_to_migration_names(MIGRATION_FILES, OLD_PLUGIN_NAME)
    Migration::MigrationSquasher.squash(migration_names) do
      create_table "cost_queries" do |t|
        t.integer  "user_id",                                       :null => false
        t.integer  "project_id"
        t.string   "name",                                          :null => false
        t.boolean  "is_public",                  :default => false, :null => false
        t.datetime "created_on",                                    :null => false
        t.datetime "updated_on",                                    :null => false
        t.string   "serialized", :limit => 2000,                    :null => false
      end

      add_timestamps :custom_fields
    end
  end

  def down
    drop_table "cost_queries"
    remove_timestamps :custom_fields
  end
end

