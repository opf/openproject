class CostQuery::Filter::Tweek < Report::Filter::Base
  use :integer_operators

  def self.label
    I18n.t(:label_week_reporting)
  end

  def self.available_values(*)
    1.upto(53).map {|i| [ i.to_s, i ]}
  end
end
