# frozen_string_literal: true

# Test Assistant (0014):
# * the "Use test management AI" permission (use_test_ai, never used by a page) becomes
#   "Use test assistant" (use_test_assistant); roles that had it keep it.
# * the unused project setting enable_ai ("Enable Generate & Chat", off by default) is dropped.
#   The assistant has its own setting enable_test_assistant, on unless switched off.
class RenameTestAIPermissionAndSetting < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL.squish
      UPDATE role_permissions SET permission = 'use_test_assistant'
      WHERE permission = 'use_test_ai'
        AND NOT EXISTS (SELECT 1 FROM role_permissions other
                        WHERE other.role_id = role_permissions.role_id AND other.permission = 'use_test_assistant')
    SQL
    execute "DELETE FROM role_permissions WHERE permission = 'use_test_ai'"
    execute "UPDATE tm_project_settings SET options = options - 'enable_ai' WHERE options ? 'enable_ai'"
  end

  def down
    execute "UPDATE role_permissions SET permission = 'use_test_ai' WHERE permission = 'use_test_assistant'"
  end
end
