class CostQuery::GroupBy
  class StatusId < Base
    join_table Issue
    applies_for :label_issue_attributes

    def self.label
      Issue.human_attribute_name(:status)
    end
  end
end
