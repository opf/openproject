# frozen_string_literal: true

# "Last edited by" for test cases. author_id already exists (since the initial
# migration); this adds updated_by_id. No backfill: unknown values render as "—".
#
# The user FKs on tm_test_cases are (re)created with ON DELETE SET NULL so that
# deleting a user in OpenProject is not blocked by test cases they authored,
# were assigned to, or last edited.
class AddUpdatedByToTmTestCases < ActiveRecord::Migration[8.0]
  def up
    add_reference :tm_test_cases,
                  :updated_by,
                  null: true,
                  index: true,
                  foreign_key: { to_table: :users, on_delete: :nullify }

    %i[author_id assigned_to_id].each do |column|
      remove_foreign_key :tm_test_cases, column: column if foreign_key_exists?(:tm_test_cases, column: column)
      add_foreign_key :tm_test_cases, :users, column: column, on_delete: :nullify
    end
  end

  def down
    %i[author_id assigned_to_id].each do |column|
      remove_foreign_key :tm_test_cases, column: column if foreign_key_exists?(:tm_test_cases, column: column)
      add_foreign_key :tm_test_cases, :users, column: column
    end

    remove_reference :tm_test_cases, :updated_by, foreign_key: { to_table: :users }, index: true
  end
end
