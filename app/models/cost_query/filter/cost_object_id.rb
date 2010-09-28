class CostQuery::Filter::CostObjectId < CostQuery::Filter::Base
  join_table Project
  label :field_cost_object
  applies_for :label_issue_attributes

  def self.available_values(*)
    ([[l(:caption_labor), -1]] + CostObject.find(:all, :order => 'name').map { |t| [t.name, t.id] })
  end
end
