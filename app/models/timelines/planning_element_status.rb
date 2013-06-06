class Timelines::PlanningElementStatus < Enumeration
  unloadable

  has_many :planning_elements, :class_name  => "Timelines::PlanningElement",
                               :foreign_key => 'planning_element_status_id'

  OptionName = :enumeration_planning_element_statuses

  def option_name
    OptionName
  end

  def objects_count
    planning_elements.count
  end

  def transfer_relations(to)
    planning_elements.update_all(:planning_element_status_id => to.id)
  end
end
