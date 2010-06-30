class CostQuery::Filter::UserId < CostQuery::Filter::Base
  label :field_user

  def self.available_values
    User.all.map { |u| [u.name, u.id] }
  end
end
