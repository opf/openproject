class Report::Filter::NoFilter < Report::Filter::Base
  table_name "entries"
  dont_display!
  singleton

  def sql_statement
    raise NotImplementedError, "My subclass should have overwritten 'sql_statement'"
  end
end
