require Rails.root.join("db","migrate","migration_utils","migration_squasher").to_s
require Rails.root.join("db","migrate","migration_utils","setting_renamer").to_s
require 'open_project/plugins/migration_mapping'
# This migration aggregates the migrations detailed in MIGRATION_FILES
class AggregatedBacklogsMigrations < ActiveRecord::Migration

  def initialize
    super
    @issues_table_exists = ActiveRecord::Base.connection.tables.include? 'issues'
  end

  REPLACED = {
    "story_trackers" => "story_types",
    "task_tracker" => "task_type"
  }

  MIGRATION_FILES = <<-MIGRATIONS
    011_create_stories_tasks_sprints_and_burndown.rb
    017_change_issue_position_column.rb
    20110321145023_create_version_setting.rb
    20110513130147_remove_sprint_start_date.rb
    20110610134000_add_projects_issue_statuses.rb
    20111014073605_drop_burndown_days.rb
  MIGRATIONS

  OLD_PLUGIN_NAME = "chiliproject_backlogs"

  def up
    migration_names = OpenProject::Plugins::MigrationMapping.migration_files_to_migration_names(MIGRATION_FILES, OLD_PLUGIN_NAME)
    Migration::MigrationSquasher.squash(migration_names) do
      create_table "version_settings" do |t|
        t.integer  "project_id"
        t.integer  "version_id"
        t.integer  "display"
        t.datetime "created_at", :null => false
        t.datetime "updated_at", :null => false
      end
      add_index "version_settings", ["project_id", "version_id"], :name => "index_version_settings_on_project_id_and_version_id"

      create_table "issue_done_statuses_for_project", :id => false do |t|
        t.integer "project_id"
        t.integer "issue_status_id"
      end

      if(@issues_table_exists)
        change_table "issues" do |t|
          t.integer  "position"
          t.integer  "story_points"
          t.float    "remaining_hours"
        end
      end
    end
    Migration::SettingRenamer.rename("plugin_backlogs","plugin_openproject_backlogs")
    # Rename Tracker to Type
    Setting['plugin_openproject_backlogs'] = replace(Setting['plugin_openproject_backlogs'], REPLACED)
  end

  def down
    drop_table "version_settings"
    drop_table "issue_done_statuses_for_project"
    if(@issues_table_exists)
      change_table "issues" do |t|
        remove_column "position"
        remove_column "story_points"
        remove_column "remaining_hours"
      end
    end
    Setting['plugin_openproject_backlogs'] = replace(Setting['plugin_openproject_backlogs'], REPLACED.invert)
  end

  private

  def replace(hash,mapping)
    Hash[hash.map { |k,v| [mapping[k] || k, v] }]
  end

  def settings_table
    @settings_table ||= ActiveRecord::Base.connection.quote_table_name('settings')
  end

  def quote_value s
    ActiveRecord::Base.connection.quote(s)
  end
end



