require 'typed_dag/sql/relation_access'

module TypedDag::Sql::SelectClosure
  def self.sql(relation)
    Sql.new(relation).sql
  end

  class Sql
    include TypedDag::Sql::RelationAccess

    def initialize(relation)
      self.relation = relation
    end

    def sql
      <<-SQL
        SELECT
          #{from_column},
          #{to_column},
          #{type_columns.join(', ')},
          SUM(#{count_column}) AS #{count_column}
        FROM
          (SELECT
            r1.#{from_column},
            r2.#{to_column},
            #{depth_sum_case},
            r1.#{count_column} * r2.#{count_column} AS #{count_column}
          FROM
            #{table_name} r1
          JOIN
            #{table_name} r2
          ON
            (#{relations_join_combines_paths_condition})) unique_rows
        GROUP BY
          #{from_column},
          #{to_column},
          #{type_columns.join(', ')}
      SQL
    end

    private

    def depth_sum_case
      type_columns.map do |column|
        <<-SQL
          CASE
            WHEN r1.#{to_column} = r2.#{from_column} AND (r1.#{column} > 0 OR r2.#{column} > 0)
            THEN r1.#{column} + r2.#{column}
            WHEN r1.#{to_column} != r2.#{from_column}
            THEN r1.#{column} + r2.#{column} + #{relation.send(column)}
            ELSE 0
            END AS #{column}
        SQL
      end.map(&:strip).join(', ')
    end

    def relations_join_combines_paths_condition
      <<-SQL
        r1.#{to_column} = #{from_id_value}
        AND r2.#{from_column} = #{to_id_value}
        AND NOT (r1.#{from_column} = #{from_id_value} AND r2.#{to_column} = #{to_id_value})
      SQL
    end
  end
end
