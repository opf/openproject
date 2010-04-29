class CostQuery::Filter::IssueId < CostQuery::Filter::Base
  def available_values
    Issue.all.map { |i| [i.name, i.id] }
  end
end
