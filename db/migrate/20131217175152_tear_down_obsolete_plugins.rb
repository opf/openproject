##
# This is the one migration that is fairly specific to the cockpit configuration.
#
# It removes all tables of the following plugins which were part of said configuration:
#
#   - stuff_to_do_plugin
#   - redmine_fb_statistics
#   - redmine_fb_importer
class TearDownObsoletePlugins < ActiveRecord::Migration
  def self.up
    # remove stuff_to_do_plugin tables
    try_drop_table :time_grid_issues_users
    try_drop_table :stuff_to_dos
    try_drop_table :next_issues

    # drop redmine_fb_statistics tables
    try_drop_table :siemens_statistics

    # drop redmine_fb_importer tables
    try_drop_table :import_jobs
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration "Cannot restore delete plugins' tables."
  end

  protected

  def try_drop_table(table_name)
    begin
      drop_table table_name
    rescue
      puts "[warning] could not drop table #{table_name}"
    end
  end
end
