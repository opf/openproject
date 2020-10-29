require 'typed_dag/sql/helper'

module TypedDag::Sql::InsertClosureOfDepth
  def self.sql(configuration, depth)
    Sql.new(configuration).sql(depth)
  end

  class Sql
    def initialize(configuration)
      self.helper = ::TypedDag::Sql::Helper.new(configuration)
    end

    def sql(depth)
      if helper.mysql_db?
        sql_mysql(depth)
      else
        sql_postgresql(depth)
      end
    end

    private

    def sql_mysql(depth)
      <<-SQL
        #{insert_sql(depth)}
        ON DUPLICATE KEY
        UPDATE #{helper.table_name}.#{helper.count_column} = #{helper.table_name}.#{helper.count_column} + VALUES(#{helper.count_column})
      SQL
    end

    def sql_postgresql(depth)
      <<-SQL
        #{insert_sql(depth)}
        ON CONFLICT (#{insert_list})
        DO UPDATE SET #{helper.count_column} = #{helper.table_name}.#{helper.count_column} + EXCLUDED.#{helper.count_column}
      SQL
    end

    def insert_sql(depth)
      <<-SQL
        INSERT INTO #{helper.table_name}
          (#{insert_list}, #{helper.count_column})
        SELECT #{insert_list}, #{helper.count_column} FROM
          (#{sum_select(depth)}) to_insert
      SQL
    end

    def sum_select(depth)
      <<-SQL
        SELECT #{select_list}, SUM(r1.#{helper.count_column} * r2.#{helper.count_column}) AS #{helper.count_column}
        FROM #{helper.table_name} r1
        JOIN #{helper.table_name} r2
        ON #{join_condition(depth)}
        GROUP BY #{group_list}
      SQL
    end

    def insert_list
      [helper.from_column,
       helper.to_column,
       helper.type_select_list].join(', ')
    end

    def select_list
      <<-SQL
        r1.#{helper.from_column},
        r2.#{helper.to_column},
        #{helper.type_select_summed_columns_aliased('r1', 'r2')}
      SQL
    end

    def group_list
      <<-SQL
        r1.#{helper.from_column},
        r2.#{helper.to_column},
        #{helper.type_select_summed_columns('r1', 'r2')}
      SQL
    end

    def join_condition(depth)
      <<-SQL
        r1.#{helper.to_column} = r2.#{helper.from_column}
        AND (#{helper.sum_of_type_columns('r1.')} = #{depth})
        AND (#{helper.sum_of_type_columns('r2.')} = 1)
      SQL
    end

    attr_accessor :helper
  end
end
