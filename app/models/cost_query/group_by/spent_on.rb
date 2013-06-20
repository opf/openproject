class CostQuery::GroupBy::SpentOn < Report::GroupBy::Base
  def self.label
    I18n.t(:label_spent_on_reporting)
  end
end
