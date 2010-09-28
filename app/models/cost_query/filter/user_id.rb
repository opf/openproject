class CostQuery::Filter::UserId < CostQuery::Filter::Base
  label :field_user

  def self.available_values(*)
    users = Project.visible.collect {|p| p.users}.flatten.uniq.sort
    values = users.map { |u| [u.name, u.id] }
    values.delete_if { |u| (u.first.include? "Redmine Admin") || (u.first.include? "Anonymous")}
    values.sort!
    values.unshift ["<< #{l(:label_me)} >>", User.current.id.to_s] if User.current.logged?
    values
  end
end
