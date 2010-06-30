class CostQuery::Filter::StatusId < CostQuery::Filter::Base
  available_operators 'c', 'o'
  join_table Issue, IssueStatus => [Issue, :status]
  label :field_status

  def self.available_values
    IssueStatus.all.map { |i| [i.name, i.id] }
  end
end
