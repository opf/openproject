module CostQuery::GroupBy
  module RubyAggregation
    def responsible_for_sql?
      false
    end

    def result
      data = child.result.group_by do |entry|
        group_fields.inject({}) { |hash, key| hash.merge key => entry.fields[key] }
      end
      list = data.keys.map { |fields| CostQuery::Result.new data[fields], fields }
      CostQuery::Result.new list
    end
  end
end