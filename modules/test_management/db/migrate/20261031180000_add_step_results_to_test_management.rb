# frozen_string_literal: true

# Step results and the result error field (0020).
# - tm_test_results.error_message / error_trace: the printed error of a result (automation: the
#   reported failure message and stack trace; earlier uploads kept the trace in details["stack"],
#   which is copied over, and the message from the result comment).
# - tm_test_step_results: per-step outcome of one result. kind "case" rows belong to a step of the
#   case (test_step_id; the action is kept as a snapshot so the history survives step edits or
#   deletion); kind "reported" rows are reported steps that matched no case step. Used by automated
#   uploads (Playwright, Allure, Cucumber, native) and by manual execution (actual_result).
class AddStepResultsToTestManagement < ActiveRecord::Migration[8.0]
  class MigrationResult < ApplicationRecord
    self.table_name = "tm_test_results"
  end

  def up
    add_column :tm_test_results, :error_message, :text
    add_column :tm_test_results, :error_trace, :text

    create_table :tm_test_step_results do |t|
      t.references :result, null: false, index: true,
                            foreign_key: { to_table: :tm_test_results, on_delete: :cascade }
      t.references :test_step, index: true, foreign_key: { to_table: :tm_test_steps, on_delete: :nullify }
      t.string :kind, null: false, default: "case", limit: 16
      t.integer :position, null: false, default: 0
      t.string :status, null: false, default: "untested", limit: 16
      t.string :match_method, limit: 16
      t.text :step_action
      t.text :reported_title
      t.integer :duration_ms
      t.text :error_message
      t.text :error_trace
      t.text :actual_result
      t.jsonb :details, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :tm_test_step_results, %i[result_id position]

    MigrationResult.reset_column_information
    MigrationResult.where(source: "automation").find_each do |result|
      stack = (result.details || {})["stack"]
      message = result.status == "passed" ? nil : result.comment.to_s.sub(/\A\[[^\]]*\] /, "").presence
      next if stack.blank? && message.blank?

      result.update_columns(error_trace: stack.presence&.first(16_000), error_message: message&.first(4000))
    end
  end

  def down
    drop_table :tm_test_step_results
    remove_column :tm_test_results, :error_trace
    remove_column :tm_test_results, :error_message
  end
end
