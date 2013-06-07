#we have to require this here because the operators would not be defined otherwise
require_dependency 'cost_query/operator'
class CostQuery::Filter::StatusId < CostQuery::Filter::Base
  available_operators 'c', 'o'
  join_table Issue, IssueStatus => [Issue, :status]
  applies_for :label_issue_attributes

  def self.label
    Issue.human_attribute_name(:status)
  end

  def self.available_values(*)
    IssueStatus.find(:all, :order => 'name').map { |i| [i.name, i.id] }
  end
end
