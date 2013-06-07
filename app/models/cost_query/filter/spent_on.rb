class CostQuery::Filter::SpentOn < CostQuery::Filter::Base
  use :time_operators

  def self.label
    I18n.t(:label_spent_on_reporting)
  end
end
