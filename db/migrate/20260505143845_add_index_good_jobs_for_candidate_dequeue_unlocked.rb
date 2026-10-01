# frozen_string_literal: true

class AddIndexGoodJobsForCandidateDequeueUnlocked < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :good_jobs, %i[priority scheduled_at id],
              name: :index_good_jobs_for_candidate_dequeue_unlocked,
              order: { priority: "ASC NULLS LAST", scheduled_at: :asc, id: :asc },
              where: "finished_at IS NULL AND locked_by_id IS NULL",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
