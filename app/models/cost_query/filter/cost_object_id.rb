class CostQuery::Filter::CostObjectId < Report::Filter::Base
  join_table Project
  applies_for :label_work_package_attributes

  def self.label
    CostObject.model_name.human
  end

  def self.available_values(*)
    ([[l(:caption_labor), -1]] + CostObject.find(:all, :order => 'name').map { |t| [t.name, t.id] })
  end
end
