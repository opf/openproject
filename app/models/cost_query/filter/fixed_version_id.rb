class CostQuery::Filter::FixedVersionId < CostQuery::Filter::Base
  use :null_operators
  join_table Issue
  applies_for :label_issue_attributes
  label :field_fixed_version

  def self.available_values(user)
    versions = Version.find :all, :order => 'name', :conditions => {:project_id => Project.visible.map{|p| p.id}}
    versions.map { |a| ["#{a.name} (#{a.project.name})", a.id] }
  end
end
