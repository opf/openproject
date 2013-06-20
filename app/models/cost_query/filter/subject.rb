class CostQuery::Filter::Subject < Report::Filter::Base
  use :string_operators
  join_table Issue
  applies_for :label_issue_attributes

  def self.label
    Issue.human_attribute_name(:subject)
  end
end
