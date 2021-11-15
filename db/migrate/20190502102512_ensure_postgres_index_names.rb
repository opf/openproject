class EnsurePostgresIndexNames < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    sql = <<~SQL
      SELECT
        FORMAT('%s_pkey', table_name) as new_name,
        constraint_name as old_name
      FROM information_schema.table_constraints
      WHERE UPPER(constraint_type) = 'PRIMARY KEY'
      AND constraint_schema IN (select current_schema())
      AND constraint_name != FORMAT('%s_pkey', table_name)
      ORDER BY table_name;
    SQL

    ActiveRecord::Base.connection.execute(sql).each do |entry|
      old_name = entry['old_name']
      new_name = entry['new_name']

      ActiveRecord::Base.transaction do
        execute %(ALTER INDEX "#{old_name}" RENAME TO #{new_name};)
      rescue StandardError => e
        warn "Failed to rename index #{old_name} to #{new_name}: #{e.message}. Skipping"
      end
    end
  end

  def down
    # Nothing to do
  end
end
