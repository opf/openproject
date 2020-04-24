class RenameFixedVersion < ActiveRecord::Migration[6.0]
  def up
    rename_column :work_packages, :fixed_version_id, :version_id
    rename_column :work_package_journals, :fixed_version_id, :version_id

    rename_query_attributes('fixed_version', 'version')
  end

  def down
    rename_column :work_packages, :version_id, :fixed_version_id
    rename_column :work_package_journals, :version_id, :fixed_version_id

    rename_query_attributes('version', 'fixed_version')
  end

  def rename_query_attributes(from, to)
    ActiveRecord::Base.connection.exec_query(
      <<-SQL
        UPDATE
          queries q_sink
        SET
          filters = regexp_replace(q_source.filters, '(\n)#{from}_id:(\n)', '\\1#{to}_id:\\2'),
          column_names = regexp_replace(q_source.column_names, ':#{from}', ':#{to}'),
          sort_criteria = regexp_replace(q_source.sort_criteria, '#{from}', '#{to}'),
          group_by = regexp_replace(q_source.group_by, '#{from}', '#{to}')
        FROM
          queries q_source
        WHERE
          (q_source.filters LIKE '%#{from}_id:%'
          OR q_source.column_names LIKE '%#{from}%'
          OR q_source.sort_criteria LIKE '%#{from}%'
          OR q_source.group_by = '#{from}')
          AND q_sink.id = q_source.id
    SQL
    )
  end
end
