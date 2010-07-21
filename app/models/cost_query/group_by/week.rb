module CostQuery::GroupBy
  class Week < Base
    label :label_week
    def sql_statement
      super.select :week => iso_year_week(:spent_on, :entires)
    end
  end
end
