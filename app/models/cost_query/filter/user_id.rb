class CostQuery::Filter::UserId < CostQuery::Filter::Base
  def available_values
    User.all.map { |u| [u.name, u.id] }
  end
end
