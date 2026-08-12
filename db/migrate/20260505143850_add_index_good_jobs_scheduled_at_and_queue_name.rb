# frozen_string_literal: true

class AddIndexGoodJobsScheduledAtAndQueueName < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :good_jobs, %i[scheduled_at queue_name],
              name: :index_good_jobs_on_scheduled_at_and_queue_name,
              algorithm: :concurrently,
              if_not_exists: true
  end
end
