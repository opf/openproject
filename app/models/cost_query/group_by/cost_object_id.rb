class CostQuery::GroupBy::CostObjectId < Report::GroupBy::Base
  join_table Issue
  applies_for :label_issue_attributes

  def self.label
    CostObject.model_name.human
  end
end
