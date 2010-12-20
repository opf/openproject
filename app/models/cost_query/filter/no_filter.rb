class CostQuery::Filter::NoFilter < Report::Filter::NoFilter
  table_name "entries"
  dont_display!
  singleton

  def sql_statement
    CostQuery::SqlStatement.for_entries
  end
end
