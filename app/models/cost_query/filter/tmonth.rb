class CostQuery::Filter::Tmonth < CostQuery::Filter::Base
  use :integer_operators
  label I18n.t(:label_month_reporting)

  def self.available_values(*)
    1.upto(12).map {|i| [ ::I18n.t('date.month_names')[i], i ]}
  end
end
