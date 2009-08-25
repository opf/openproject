module DeliverablesHelper
  include ApplicationHelper
    
  # Check if the current user is allowed to manage the budget.  Based on Role
  # permissions.
  def allowed_management?
    return User.current.allowed_to?(:edit_deliverables, @project)
  end
  
  def allowed_projects_for_edit
    cond = ARCondition.new
    cond << Project.allowed_to_condition(User.current, :edit_deliverables)
    
    projects = User.current.projects.find(:all, :conditions => cond.conditions, :include => :parent).group_by(&:root)
    
    result = []
    projects.keys.sort.each do |root|
      result << root
      projects[root].sort.each do |project|
        next if project == root
        project.name = '&#187; ' + h(project.name)
        result << project
      end
    end
    result
  end
  
  def add_deliverable_cost_link(name)
    link_to_function name do |page|
      page.insert_html :bottom, :deliverable_costs_body, :partial => "deliverable_cost", :object => DeliverableCost.new
    end
  end
  
  def fields_for_deliverable_cost(deliverable_cost, &block)
    prefix = deliverable_cost.new_record? ? "new" : "existing"
    fields_for("deliverable[#{prefix}_deliverable_cost_attributes][]", deliverable_cost, &block)
  end
  
  def function_update_deliverable_cost
    #remote_function(:url => {:action => :update_deliverable_costs_row},
    #  :with => "'cost_type_id=' + encodeURIComponent(value) + '&units=' + encodeURIComponent(this.parentElement.previousSibling.firstChild.value) + '&element_id=deliverable_costs#{suffix}_#{row_id}'") %>
  end

  def add_deliverable_hour_link(name)
    link_to_remote name do |page|
      page.insert_html :bottom, "deliverable_hours_body", :partial => "deliverable_hour", :object => DeliverableHour.new
    end
  end

end