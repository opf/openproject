# frozen_string_literal: true

class CleanupBacklogsVersionsDefaultFoldStateFromUserPref < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE user_preferences
      SET settings = settings - 'backlogs_versions_default_fold_state'
      WHERE settings ? 'backlogs_versions_default_fold_state'
    SQL
  end
end
