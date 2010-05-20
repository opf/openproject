module CostQuery::GroupBy
  module RubyAggregation
    def responsible_for_sql?
      false
    end

    ##
    # @return [CostQuery::Result] aggregation
    def result
      # sub results, have fields
      # i.e. grouping by foo, bar
      data = child.result.group_by do |entry|
        # index for group is a hash
        # i.e. { :foo => 10, :bar => 20 }
        all_group_fields.inject({}) { |hash, key| hash.merge key => entry.fields[key] }
      end
      # map group back to array, all fields with same key get grouped into one list
      list = data.keys.map { |fields| CostQuery::Result.new data[fields], fields }
      # create a single result from that list
      CostQuery::Result.new list
    end
  end
end