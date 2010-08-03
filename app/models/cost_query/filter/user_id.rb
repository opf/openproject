class CostQuery::Filter::UserId < CostQuery::Filter::Base
  label :field_user

  def self.available_values
    values = User.all.map { |u| [u.name, u.id] }
    values.delete_if { |u| (u.first.include? "Redmine Admin") || (u.first.include? "Anonymous")}
    values.sort!
    values.unshift ["<< #{l(:label_me)} >>", User.current.id.to_s] if User.current.logged?
    values
  end
end
