# frozen_string_literal: true

class AddIndexGoodJobsCreatedAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :good_jobs, :created_at,
              name: :index_good_jobs_on_created_at,
              algorithm: :concurrently,
              if_not_exists: true
  end
end
