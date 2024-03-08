# frozen_string_literal: true

class CreateGoodJobsErrorEvent < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.column_exists?(:good_jobs, :error_event)
      end
    end

    add_column :good_jobs, :error_event, :integer, limit: 2
    add_column :good_job_executions, :error_event, :integer, limit: 2
  end
end
