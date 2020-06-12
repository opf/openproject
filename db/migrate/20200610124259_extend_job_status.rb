class ExtendJobStatus < ActiveRecord::Migration[6.0]
  # ALTER TYPE has to run outside transaction
  disable_ddl_transaction!

  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          ALTER TYPE delayed_job_status ADD VALUE IF NOT EXISTS 'cancelled';
        SQL
      end
    end

    ActiveRecord::Base.transaction do
      remove_reference :delayed_job_statuses, :job

      change_table :delayed_job_statuses do |t|
        t.references :user, index: true
        t.string :job_id, index: true
        t.jsonb :payload
      end


      # Now that we have user reference on job status
      # we don't need it on export
      remove_reference :work_package_exports, :user
    end
  end
end
