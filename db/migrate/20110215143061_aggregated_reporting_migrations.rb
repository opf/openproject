require Rails.root.join("db","migrate","migration_utils","migration_squasher").to_s
require 'open_project/plugins/migration_mapping'
# This migration aggregates the migrations detailed in MIGRATION_FILES
class AggregatedReportingMigrations < ActiveRecord::Migration

  def initialize
    super
    # @issues_table_exists = ActiveRecord::Base.connection.tables.include? 'issues'
  end

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
      remove_column :cost_queries, :filters
      remove_column :cost_queries, :group_by
      remove_column :cost_queries, :granularity
      remove_column :cost_queries, :display_cost_entries
      remove_column :cost_queries, :display_time_entries

      add_column :cost_queries, :serialized, :string, limit: 2000, null: false
      add_timestamps :custom_fields
    end
  end

  def down
    add_column :cost_queries, :filters, :text
    add_column :cost_queries, :group_bys, :text
    add_column :cost_queries, :granularity, :string
    add_column :cost_queries, :display_cost_entries, :boolean, default: true
    add_column :cost_queries, :display_time_entries, :boolean, default: true

    remove_column :cost_queries, :serialized
    remove_timestamps :custom_fields
  end
end

