class CostQuery::Filter::Tyear < CostQuery::Filter::Base
  use :integer_operators
  label :label_year_reporting

  def self.available_values(*)
    1970.upto(Date.today.year).map {|i| [ i.to_s, i ]}.reverse
  end
end
