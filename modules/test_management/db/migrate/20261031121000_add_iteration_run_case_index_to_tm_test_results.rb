# frozen_string_literal: true

require Rails.root.join("db/migrate/migration_utils/utils")

# The run page, the iterations API and Start iteration look up "latest result per run case
# within an iteration" (GROUP BY iteration_id, run_case_id / MAX(id)). The single-column
# iteration index from 20261031120100 is a prefix of this one, so it is replaced.
class AddIterationRunCaseIndexToTmTestResults < ActiveRecord::Migration[8.0]
  include Migration::Utils

  def up
    add_index :tm_test_results, %i[iteration_id run_case_id],
              name: "index_tm_test_results_on_iteration_and_run_case"
    remove_index_on :tm_test_results, "index_tm_test_results_on_iteration_id", %w[iteration_id]
  end

  def down
    remove_index_on :tm_test_results, "index_tm_test_results_on_iteration_and_run_case",
                    %w[iteration_id run_case_id]
    add_index :tm_test_results, :iteration_id, name: "index_tm_test_results_on_iteration_id"
  end
end
