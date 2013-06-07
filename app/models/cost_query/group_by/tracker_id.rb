class CostQuery::GroupBy
  class TrackerId < Base
    join_table Issue
    applies_for :label_issue_attributes

    def self.label
      Issue.human_attribute_name(:tracker)
    end
  end
end
