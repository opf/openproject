class CostQuery::GroupBy::UserId < Report::GroupBy::Base

  def self.label
    WorkPackage.human_attribute_name(:user)
  end
end
