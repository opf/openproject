class CostQuery::GroupBy
  module RubyAggregation
    def responsible_for_sql?
      false
    end

    ##
    # @return [CostQuery::Result] aggregation
    def compute_result
      child.result.grouped_by(all_group_fields(false), type, group_fields)
    end
  end
end