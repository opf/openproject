class CostQuery::GroupBy::IssueId < Report::GroupBy::Base

  def self.label
    Issue.model_name.human
  end
end
