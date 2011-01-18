class Report::GroupBy
  module SqlAggregation
    def responsible_for_sql?
      true
    end

    def compute_result
      super.tap { |r| r.important_fields = group_fields }.grouped_by(all_group_fields(false), type, group_fields)
    end

    def sql_statement
      super.tap do |sql|
        define_group sql
        sql.count unless sql.selects.include? "count"
      end
    end
  end
end
