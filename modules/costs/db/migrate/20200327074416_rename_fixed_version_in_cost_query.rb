class RenameFixedVersionInCostQuery < ActiveRecord::Migration[6.0]
  def up
    rename_query_attributes('FixedVersion', 'Version')
  end

  def down
    rename_query_attributes('Version', 'FixedVersion')
  end

  def rename_query_attributes(from, to)
    ActiveRecord::Base.connection.exec_query(
      <<-SQL
        UPDATE
          cost_queries q_sink
        SET
          serialized = regexp_replace(q_source.serialized, '(\n- - )#{from}Id(\n)', '\\1#{to}Id\\2')
        FROM
          cost_queries q_source
        WHERE
          q_source.serialized LIKE '%#{from}%'
          AND q_sink.id = q_source.id
    SQL
    )
  end
end
