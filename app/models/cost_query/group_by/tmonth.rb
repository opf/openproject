class CostQuery::GroupBy::Tmonth < Report::GroupBy::Base

  def self.label
    I18n.t(:label_month_reporting)
  end
end
