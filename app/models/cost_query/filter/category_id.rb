class CostQuery::Filter::CategoryId < CostQuery::Filter::Base
  use :null_operators
  join_table Issue
  applies_for :label_issue_attributes
  label :field_category

  def self.available_values(user)
    categories = IssueCategory.find :all, :order => 'name', :conditions => {:project_id => Project.visible.map{|p| p.id}}
    categories.map { |c| ["#{c.name} (#{c.project.name})", c.id] }
  end
end
