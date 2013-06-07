class CostQuery::GroupBy
  class FixedVersionId < Base
    join_table Issue
    applies_for :label_issue_attributes

    def self.label
      Issue.human_attribute_name(:fixed_version)
    end
  end
end
