require 'typed_dag/sql/relation_access'
require 'typed_dag/sql/select_closure'

module TypedDag::Sql::AddClosure
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
        #{insert_sql}
        #{on_duplicate}
      SQL
    end

    private

    def on_duplicate
      if helper.mysql_db?
        on_duplicate_mysql
      else
        on_duplicate_postgresql
      end
    end

    def on_duplicate_mysql
      <<-SQL
        ON DUPLICATE KEY
        UPDATE #{count_column} = #{table_name}.#{count_column} + VALUES(#{count_column})
      SQL
    end

    def on_duplicate_postgresql
      <<-SQL
        ON CONFLICT (#{column_list})
        DO UPDATE SET #{count_column} = #{table_name}.#{count_column} + EXCLUDED.#{count_column}
      SQL
    end

    def insert_sql
      <<-SQL
        INSERT INTO #{table_name}
          (#{column_list}, #{count_column})
        #{closure_select}
      SQL
    end

    def closure_select
      TypedDag::Sql::SelectClosure.sql(relation)
    end

    def column_list
      "#{from_column}, #{to_column}, #{type_select_list}"
    end
  end
end
