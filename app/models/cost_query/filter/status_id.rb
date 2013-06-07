#we have to require this here because the operators would not be defined otherwise
require_dependency 'cost_query/operator'
class CostQuery::Filter::StatusId < CostQuery::Filter::Base
  available_operators 'c', 'o'
  join_table Issue, IssueStatus => [Issue, :status]
  applies_for :label_issue_attributes
  label :field_status

  def self.available_values(*)
    IssueStatus.find(:all, :order => 'name').map { |i| [i.name, i.id] }
  end
end
