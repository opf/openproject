class CostQuery::Filter::NoFilter < Report::Filter::NoFilter
  dont_display!
  singleton

  def sql_statement
    CostQuery::SqlStatement.for_entries
  end
end
