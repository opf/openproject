class CostQuery::Filter::Tweek < CostQuery::Filter::Base
  use_integer_operators
  label :week

  def self.available_values
    1.upto(53).map {|i| [ l(:week).capitalize + ' #' + i.to_s,i ]}
  end
end
