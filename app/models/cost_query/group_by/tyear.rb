class CostQuery::GroupBy::Tyear < Report::GroupBy::Base

  def self.label
    I18n.t(:label_year_reporting)
  end
end
