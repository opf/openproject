class MigrateSessionsUnlogged < ActiveRecord::Migration[6.1]
  def change
    truncate :sessions

    # Set the table to unlogged
    execute <<~SQL
      ALTER TABLE "sessions" SET UNLOGGED
    SQL

    # We don't need the created at column
    # that now no longer is set by rails
    remove_column :sessions, :created_at, null: false
  end
end
