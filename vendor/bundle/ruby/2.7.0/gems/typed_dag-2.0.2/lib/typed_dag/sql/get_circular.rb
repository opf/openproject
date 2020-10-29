require 'typed_dag/sql/helper'

module TypedDag::Sql::GetCircular
  def self.sql(configuration, depth)
    Sql.new(configuration).sql(depth)
  end

  class Sql
    def initialize(configuration)
      self.helper = ::TypedDag::Sql::Helper.new(configuration)
    end

    def sql(depth)
      <<-SQL
        SELECT
          r1.#{helper.from_column} AS r1_from_column,
          r1.#{helper.to_column} AS r1_to_column,
          r2.#{helper.from_column} AS r2_from_column,
          r2.#{helper.to_column} AS r2_to_column
        FROM #{helper.table_name} r1
        JOIN #{helper.table_name} r2
        ON #{join_condition(depth)}
      SQL
    end

    private

    attr_accessor :helper

    def join_condition(depth)
      <<-SQL
        r1.#{helper.from_column} = r2.#{helper.to_column}
        AND r1.#{helper.to_column} = r2.#{helper.from_column}
        AND (#{helper.sum_of_type_columns('r1.')} = 1)
        AND (#{helper.sum_of_type_columns('r2.')} = #{depth})
      SQL
    end
  end
end
