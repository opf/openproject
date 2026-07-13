# frozen_string_literal: true

class AddLockTypeToGoodJobs < ActiveRecord::Migration[8.1]
  def change
    add_column :good_jobs, :lock_type, :integer, limit: 2 unless column_exists?(:good_jobs, :lock_type)
  end
end
