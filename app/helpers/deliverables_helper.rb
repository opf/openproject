module DeliverablesHelper
  include ApplicationHelper
  
  # Check if the current user is allowed to manage the budget.  Based on Role
  # permissions.
  def allowed_management?
    return User.current.allowed_to?(:edit_deliverables, @project)
  end
  
end