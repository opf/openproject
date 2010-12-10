class Report::Filter::NoFilter < Report::Filter::Base
  dont_display!
  singleton

  def sql_statement
    raise NotImplementedError, "My subclass should have overwritten 'sql_statement'"
  end
end
