# frozen_string_literal: true

class CleanupBacklogsTaskColorFromUserPref < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings = settings - 'backlogs_task_color'
      WHERE settings ? 'backlogs_task_color'
    SQL
  end
end
