class CostQuery::GroupBy
  class CategoryId < Base
    join_table Issue
    applies_for :label_issue_attributes

    def self.label
      Issue.human_attribute_name(:category)
    end
  end
end
