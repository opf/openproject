# frozen_string_literal: true

class CreateGoodJobBatches < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        # Ensure this incremental update migration is idempotent
        # with monolithic install migration.
        return if connection.table_exists?(:good_job_batches)
      end
    end

    create_table :good_job_batches, id: :uuid do |t|
      t.timestamps
      t.text :description
      t.jsonb :serialized_properties
      t.text :on_finish
      t.text :on_success
      t.text :on_discard
      t.text :callback_queue_name
      t.integer :callback_priority
      t.datetime :enqueued_at
      t.datetime :discarded_at
      t.datetime :finished_at
    end

    change_table :good_jobs do |t|
      t.uuid :batch_id
      t.uuid :batch_callback_id

      t.index :batch_id, where: "batch_id IS NOT NULL"
      t.index :batch_callback_id, where: "batch_callback_id IS NOT NULL"
    end
  end
end
