#we have to require this here because the operators would not be defined otherwise
require_dependency 'cost_query/operator'
class CostQuery::Filter::StatusId < Report::Filter::Base
  available_operators 'c', 'o'
  join_table WorkPackage, Status => [WorkPackage, :status]
  applies_for :label_work_package_attributes

  def self.label
    WorkPackage.human_attribute_name(:status)
  end

  def self.available_values(*)
    Status.find(:all, :order => 'name').map { |i| [i.name, i.id] }
  end
end
