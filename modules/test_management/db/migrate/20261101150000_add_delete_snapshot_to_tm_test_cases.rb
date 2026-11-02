# frozen_string_literal: true

class AddDeleteSnapshotToTmTestCases < ActiveRecord::Migration[8.0]
  def change
    change_table :tm_test_cases, bulk: true do |t|
      t.bigint :deleted_from_suite_id
      t.string :deleted_from_suite_path
    end
  end
end
