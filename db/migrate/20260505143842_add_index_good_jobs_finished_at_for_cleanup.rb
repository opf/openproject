# frozen_string_literal: true

class AddIndexGoodJobsFinishedAtForCleanup < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.index_exists? :good_jobs, [:finished_at], name: :index_good_jobs_jobs_on_finished_at_only
      end
    end

    add_index :good_jobs, [:finished_at], where: "finished_at IS NOT NULL", name: :index_good_jobs_jobs_on_finished_at_only,
                                          algorithm: :concurrently
  end
end
