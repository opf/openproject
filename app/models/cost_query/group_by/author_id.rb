class CostQuery::GroupBy
  class AuthorId < Base
    join_table Issue
    applies_for :label_issue_attributes

    def self.label
      Issue.human_attribute_name(:author)
    end
  end
end
