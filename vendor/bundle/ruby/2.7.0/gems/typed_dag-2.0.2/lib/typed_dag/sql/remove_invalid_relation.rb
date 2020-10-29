require 'typed_dag/sql/helper'

module TypedDag::Sql::RemoveInvalidRelation
  def self.sql(configuration, ids)
    Sql.new(configuration).sql(ids)
  end

  class Sql
    def initialize(configuration)
      self.helper = ::TypedDag::Sql::Helper.new(configuration)
    end

    def sql(ids)
      <<-SQL
        DELETE FROM #{helper.table_name}
        WHERE id IN (
          SELECT * FROM (
            SELECT id
            FROM #{helper.table_name}
            WHERE #{where(ids)}
            ORDER BY #{order}
            LIMIT 1) id_table
          )
      SQL
    end

    private

    attr_accessor :helper

    def where(ids)
      <<-SQL
        #{helper.from_column} IN (#{ids.join(', ')})
        AND #{helper.to_column} IN (#{ids.join(', ')})
        AND #{helper.sum_of_type_columns} = 1
      SQL
    end

    def order
      helper.type_columns.reverse.map { |column| "#{column} DESC" }.join(', ')
    end
  end
end
