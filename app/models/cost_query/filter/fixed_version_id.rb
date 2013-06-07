class CostQuery::Filter::FixedVersionId < CostQuery::Filter::Base
  use :null_operators
  join_table Issue
  applies_for :label_issue_attributes

  def self.label
    Issue.human_attribute_name(:fixed_version)
  end

  def self.available_values(*)
    versions = Version.find :all, :conditions => {:project_id => Project.visible.map{|p| p.id}}
    versions.map { |a| ["#{a.project.name} - #{a.name}", a.id] }.sort_by { |a| a.first.to_s + a.second.to_s }
  end
end
