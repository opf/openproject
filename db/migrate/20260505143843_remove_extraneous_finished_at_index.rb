# frozen_string_literal: true

class RemoveExtraneousFinishedAtIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return unless connection.index_exists? :good_jobs, [:finished_at], name: :index_good_jobs_jobs_on_finished_at
      end
    end

    remove_index :good_jobs, [:finished_at], where: "retried_good_job_id IS NULL AND finished_at IS NOT NULL",
                                             name: :index_good_jobs_jobs_on_finished_at, algorithm: :concurrently
  end
end
