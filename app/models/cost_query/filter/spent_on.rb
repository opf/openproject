class CostQuery::Filter::SpentOn < Report::Filter::Base
  use :time_operators

  def self.label
    I18n.t(:label_spent_on_reporting)
  end
end
