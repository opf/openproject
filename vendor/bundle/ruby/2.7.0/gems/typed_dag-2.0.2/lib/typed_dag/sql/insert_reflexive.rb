require 'typed_dag/sql/helper'

module TypedDag::Sql::InsertReflexive
  def self.sql(configuration)
    Sql.new(configuration).sql
  end

  class Sql
    def initialize(configuration)
      self.helper = ::TypedDag::Sql::Helper.new(configuration)
    end

    def sql
      <<-SQL
        INSERT INTO #{helper.table_name}
          (#{helper.from_column},
           #{helper.to_column},
           #{helper.count_column})
        SELECT id, id, 1
        FROM #{helper.node_table_name}
      SQL
    end

    private

    attr_accessor :helper
  end
end
