require Rails.root.join('db', 'migrate', 'migration_utils', 'migration_squasher').to_s
require 'open_project/plugins/migration_mapping'
# This migration aggregates the migrations detailed in the MIGRATION_FILES
class AggregatedAnnouncementsMigrations < ActiveRecord::Migration[4.2]
  MIGRATION_FILES = <<-MIGRATIONS
    001_create_announcements.rb
    20121114100640_index_on_announcements.rb
  MIGRATIONS

  OLD_PLUGIN_NAME = 'redmine_announcements'

  def up
    migration_names = OpenProject::Plugins::MigrationMapping.migration_files_to_migration_names(MIGRATION_FILES, OLD_PLUGIN_NAME)
    Migration::MigrationSquasher.squash(migration_names) do
      create_table :announcements do |t|
        t.text :text
        t.date :show_until
        t.boolean :active, default: false
        t.timestamps
      end
      add_index :announcements, [:show_until, :active]
    end
  end

  def down
    drop_table :announcements
  end
end
