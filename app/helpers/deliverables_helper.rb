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
end