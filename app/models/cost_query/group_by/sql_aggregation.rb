module CostQuery::GroupBy
  module SqlAggregation
    def responsible_for_sql?
      true
    end

    def sql_statement
      super.tap do |sql|
        define_group sql
        sql.sum :units => :units, :real_costs => :real_costs
        sql.count
      end
    end
  end
end
