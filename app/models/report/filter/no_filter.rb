class Report::Filter::NoFilter < Report::Filter::Base
  dont_display!
  singleton

  def sql_statement
  end
end
