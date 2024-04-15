# frozen_string_literal: true

class CreateGoodJobExecutions < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.table_exists?(:good_job_executions)
      end
    end

    create_table :good_job_executions, id: :uuid do |t|
      t.timestamps

      t.uuid :active_job_id, null: false
      t.text :job_class
      t.text :queue_name
      t.jsonb :serialized_params
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.text :error

      t.index [:active_job_id, :created_at], name: :index_good_job_executions_on_active_job_id_and_created_at
    end

    change_table :good_jobs do |t|
      t.boolean :is_discrete
      t.integer :executions_count
      t.text :job_class
    end
  end
end
