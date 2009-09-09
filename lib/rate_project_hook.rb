class RateMembershipsHook < Redmine::Hook::ViewListener

  # Renders up to two additional table headers to the membership setting
  #
  # Context:
  # * :project => Current project
  #
  def view_projects_settings_members_table_header(context={})
    return unless context[:project] && context[:project].module_enabled?(:costs_module)

    result = ""
    
    user = User.current
    project = context[:project]
    
    result += content_tag(:th, l(:caption_current_rate)) if (user.allowed_to?(:view_all_rates, project) || user.allowed_to?(:view_own_rate, project))
    result += content_tag(:th, l(:caption_set_rate)) if user.allowed_to?(:change_rates, project)
    
    result
  end
 
  # Renders an AJAX from to update the member's billing rate
  #
  # Context:
  # * :project => Current project
  # * :member => Current Member record
  render_on :view_projects_settings_members_table_row, :partial => 'hooks/view_projects_settings_members_table_row'
end