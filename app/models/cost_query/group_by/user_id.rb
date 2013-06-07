class CostQuery::GroupBy
  class UserId < Base

    def self.label
      Issue.human_attribute_name(:user)
    end
  end
end
