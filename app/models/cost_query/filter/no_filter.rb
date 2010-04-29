class CostQuery::Filter::NoFilter < CostQuery::Filter::Base
  def sql_statement
    CostQuery::SqlStatement.for_entries
  end
end
