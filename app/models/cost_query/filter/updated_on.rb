class CostQuery::Filter::UpdatedOn < Report::Filter::Base
  db_field "entries.updated_on"
  use :time_operators

  def self.label
    Issue.human_attribute_name(:updated_on)
  end
end
