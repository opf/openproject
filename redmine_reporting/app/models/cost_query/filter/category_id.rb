class CostQuery::Filter::CategoryId < CostQuery::Filter::Base
  use :null_operators
  join_table Issue
  applies_for :label_issue_attributes
  label :field_category

  def self.available_values(*)
    categories = IssueCategory.find :all, :conditions => {:project_id => Project.visible.map{|p| p.id}}
    categories.map { |c| ["#{c.project.name} - #{c.name} ", c.id] }.sort_by { |a| a.first.to_s + a.second.to_s }
  end
end
