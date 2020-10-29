require 'typed_dag/sql/helper'

module TypedDag::Sql::DeleteZeroCount
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
        DELETE FROM #{table_name}
        WHERE #{count_column} = 0
      SQL
    end
  end
end