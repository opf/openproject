# frozen_string_literal: true

# Lightweight audit trail for test cases (History tab). The PoC deliberately does
# not use acts_as_journalized (that needs journal data tables, journal
# formatters and API wiring); one row per create/update with a JSON diff is enough.
class CreateTmTestCaseEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :tm_test_case_events do |t|
      t.references :test_case,
                   null: false,
                   index: true,
                   foreign_key: { to_table: :tm_test_cases, on_delete: :cascade }
      t.references :user,
                   null: true,
                   index: true,
                   foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :action, null: false, limit: 32
      t.jsonb :details, null: false, default: {}
      t.datetime :created_at, null: false
    end

    add_index :tm_test_case_events, %i[test_case_id created_at]
  end
end
