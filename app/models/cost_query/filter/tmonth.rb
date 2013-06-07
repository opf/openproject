class CostQuery::Filter::Tmonth < CostQuery::Filter::Base
  use :integer_operators

  def self.label
    I18n.t(:label_month_reporting)
  end

  def self.available_values(*)
    1.upto(12).map {|i| [ ::I18n.t('date.month_names')[i], i ]}
  end
end
