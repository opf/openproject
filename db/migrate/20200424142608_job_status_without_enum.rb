class JobStatusWithoutEnum < ActiveRecord::Migration[6.0]
  def up
    add_column :delayed_job_statuses, :status_new, :integer

    map = <<-CASE
       WHEN 'in_queue' THEN 0
       WHEN 'in_process' THEN 1
       WHEN 'error' THEN 2
       WHEN 'success' THEN 3
       WHEN 'failure' THEN 4
    CASE

    update_new_column(map)

    remove_column :delayed_job_statuses, :status
    rename_column :delayed_job_statuses, :status_new, :status
    change_column :delayed_job_statuses, :status, :integer, default: 0

    execute <<-SQL
      DROP TYPE delayed_job_status;
    SQL
  end

  def down
    execute <<-SQL
      CREATE TYPE delayed_job_status AS ENUM ('in_queue', 'error', 'in_process', 'success', 'failure');
    SQL

    add_column :delayed_job_statuses, :status_new, :delayed_job_status

    map = <<-CASE
      WHEN 0 THEN 'in_queue'::delayed_job_status
      WHEN 1 THEN 'in_process'::delayed_job_status
      WHEN 2 THEN 'error'::delayed_job_status
      WHEN 3 THEN 'success'::delayed_job_status
      WHEN 4 THEN 'failure'::delayed_job_status
    CASE

    update_new_column(map)

    remove_column :delayed_job_statuses, :status
    rename_column :delayed_job_statuses, :status_new, :status
    change_column :delayed_job_statuses, :status, :delayed_job_status, default: 'in_queue'
  end

  def update_new_column(map)
    ActiveRecord::Base.connection.exec_query(
      <<-SQL
        UPDATE
          delayed_job_statuses s_sink
        SET
          status_new = CASE s_source.status
                       #{map}
                       END
        FROM
          delayed_job_statuses s_source
        WHERE
          s_sink.id = s_source.id
      SQL
    )
  end
end
