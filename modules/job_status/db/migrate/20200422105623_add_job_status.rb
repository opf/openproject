class AddJobStatus < ActiveRecord::Migration[6.0]
  def up
    execute <<-SQL
      CREATE TYPE delayed_job_status AS ENUM ('in_queue', 'error', 'in_process', 'success', 'failure');
    SQL

    create_table :delayed_job_statuses do |t|
      t.references :job
      t.references :reference, polymorphic: true, index: { unique: true }
      t.string :message

      t.timestamps
    end

    add_column :delayed_job_statuses, :status, :delayed_job_status, default: 'in_queue'
  end

  def down
    drop_table :delayed_job_statuses

    execute <<-SQL
      DROP TYPE delayed_job_status;
    SQL
  end
end
