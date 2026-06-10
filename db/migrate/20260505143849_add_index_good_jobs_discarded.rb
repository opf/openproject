# frozen_string_literal: true

class AddIndexGoodJobsDiscarded < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :good_jobs, :finished_at,
              name: :index_good_jobs_on_discarded,
              order: { finished_at: :desc },
              where: "finished_at IS NOT NULL AND error IS NOT NULL",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
