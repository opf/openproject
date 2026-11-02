# frozen_string_literal: true

# 0013: the Executions placeholder and its "Enable Executions" project setting were dropped
# (test runs and their iterations are the single execution entity). Remove the stale flag
# from the settings JSON. Nothing to restore on rollback: the flag had no effect.
class RemoveExecutionsSettingFromTmProjectSettings < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      UPDATE tm_project_settings
      SET options = options - 'enable_executions'
      WHERE options ? 'enable_executions'
    SQL
  end

  def down
    # no-op
  end
end
