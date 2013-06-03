class CostQuery::GroupBy
  class UserId < Base
    label Issue.human_attribute_name(:user)
  end
end
