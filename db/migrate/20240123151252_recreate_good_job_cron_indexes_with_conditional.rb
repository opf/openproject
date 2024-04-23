# frozen_string_literal: true

class RecreateGoodJobCronIndexesWithConditional < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at_cond)
          add_index :good_jobs, [:cron_key, :created_at], where: "(cron_key IS NOT NULL)",
                    name: :index_good_jobs_on_cron_key_and_created_at_cond, algorithm: :concurrently
        end
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at_cond)
          add_index :good_jobs, [:cron_key, :cron_at], where: "(cron_key IS NOT NULL)", unique: true,
                    name: :index_good_jobs_on_cron_key_and_cron_at_cond, algorithm: :concurrently
        end

        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_created_at
        end
        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_cron_at
        end
      end

      dir.down do
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at)
          add_index :good_jobs, [:cron_key, :created_at],
                    name: :index_good_jobs_on_cron_key_and_created_at, algorithm: :concurrently
        end
        unless connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at)
          add_index :good_jobs, [:cron_key, :cron_at], unique: true,
                    name: :index_good_jobs_on_cron_key_and_cron_at, algorithm: :concurrently
        end

        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_created_at_cond)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_created_at_cond
        end
        if connection.index_name_exists?(:good_jobs, :index_good_jobs_on_cron_key_and_cron_at_cond)
          remove_index :good_jobs, name: :index_good_jobs_on_cron_key_and_cron_at_cond
        end
      end
    end
  end
end
