class CostQuery::GroupBy::Tweek < Report::GroupBy::Base

  def self.label
    I18n.t(:label_week_reporting)
  end
end
