class CostQuery::Filter::Tweek < CostQuery::Filter::Base
  use :integer_operators
  label :label_week_reporting

  def self.available_values(*)
    1.upto(53).map {|i| [ i.to_s, i ]}
  end
end
