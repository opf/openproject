module CostQuery::GroupBy
  module SqlAggregation
    include Report::GroupBy::SqlAggregation

    def sql_statement
      super.tap do |sql|
        sql.sum :units => :units, :real_costs => :real_costs, :display_costs => :display_costs
      end
    end
  end
end
