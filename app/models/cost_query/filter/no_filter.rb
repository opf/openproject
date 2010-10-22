class CostQuery::Filter::NoFilter < CostQuery::Filter::Base
  dont_display!
  singleton

  def sql_statement
    CostQuery::SqlStatement.for_entries
  end
end
