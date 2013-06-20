class CostQuery::GroupBy::UserId < Report::GroupBy::Base

  def self.label
    Issue.human_attribute_name(:user)
  end
end
