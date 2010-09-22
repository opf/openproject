class CostQuery::Filter::Tyear < CostQuery::Filter::Base
  use :integer_operators
  label :label_year

  def self.available_values(user)
    1970.upto(Date.today.year).map {|i| [ l(label) + ' #' + i.to_s,i ]}.reverse
  end
end
