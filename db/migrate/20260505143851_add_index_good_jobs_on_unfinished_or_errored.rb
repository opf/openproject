# frozen_string_literal: true

class AddIndexGoodJobsOnUnfinishedOrErrored < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :good_jobs, :id,
              name: :index_good_jobs_on_unfinished_or_errored,
              where: "finished_at IS NULL OR error IS NOT NULL",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
