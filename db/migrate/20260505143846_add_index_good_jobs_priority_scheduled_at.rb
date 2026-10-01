# frozen_string_literal: true

class AddIndexGoodJobsPriorityScheduledAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.index_name_exists?(:good_jobs, "index_good_jobs_on_priority_scheduled_at_unfinished") &&
                  connection.index_name_exists?(:good_jobs, "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished")
      end
    end

    add_index :good_jobs, %i[priority scheduled_at id],
              where: "finished_at IS NULL", name: "index_good_jobs_on_priority_scheduled_at_unfinished",
              algorithm: :concurrently
    add_index :good_jobs, %i[queue_name scheduled_at id],
              where: "finished_at IS NULL", name: "index_good_jobs_on_queue_name_priority_scheduled_at_unfinished",
              algorithm: :concurrently
  end
end
