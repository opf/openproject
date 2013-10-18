require Rails.root.join("db","migrate","migration_utils","migration_squasher").to_s
require 'open_project/plugins/migration_mapping'
# This migration aggregates the migrations detailed in MIGRATION_FILES
class AggregatedMyProjectPageMigrations < ActiveRecord::Migration

  MIGRATION_FILES = <<-MIGRATIONS
    20110804151010_add_projects_overviews.rb
    20111202150017_change_serialized_columns_from_string_to_text.rb
    20120605121847_create_default_my_projects_page.rb
  MIGRATIONS

  OLD_PLUGIN_NAME = "chiliproject_my_project_page"

  def up
    migration_names = OpenProject::Plugins::MigrationMapping.migration_files_to_migration_names(MIGRATION_FILES, OLD_PLUGIN_NAME)
    Migration::MigrationSquasher.squash(migration_names) do
      create_table :my_projects_overviews do |t|
        t.integer "project_id", default: 0, null: false
        t.text "left", null: false
        t.text "right", null: false
        t.text "top", null: false
        t.text "hidden", null: false
        t.datetime "created_on", null: false
      end

      # creates a default my project page config for each project
      # that pretty much mirrors the contents of the static page
      # if there is already a my project page then don't create a second one
      Project.all.each do |project|
        unless MyProjectsOverview.exists? project_id: project.id
          MyProjectsOverview.create project: project
        end
      end
    end
  end

  def down
    drop_table :my_projects_overviews
  end
end

