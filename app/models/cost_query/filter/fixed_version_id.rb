class CostQuery::Filter::FixedVersionId < CostQuery::Filter::Base
  use :null_operators
  join_table Issue
  applies_for :label_issue
  label :field_fixed_version

  def self.available_values(param={})
    Version.all.map { |a| [a.name, a.id] }
  end
end
