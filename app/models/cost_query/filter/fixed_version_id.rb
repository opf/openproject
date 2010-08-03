class CostQuery::Filter::FixedVersionId < CostQuery::Filter::Base
  use :null_operators
  join_table Issue
  applies_for :label_issue_attributes
  label :field_fixed_version

  def self.available_values(param={})
    Version.find(:all, :order => 'name').map { |a| [a.name, a.id] }
  end
end
