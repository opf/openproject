class CostsProjectHook < Redmine::Hook::ViewListener

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
    
    result += content_tag(:th, l(:caption_current_rate)) if user.allowed_to?(:view_hourly_rates, project)
    result += content_tag(:th, l(:caption_set_rate)) if user.allowed_to?(:edit_hourly_rates, project)
    
    result
  end
 
  # Renders an AJAX form to update the member's billing rate
  # Context:
  # * :project => Current project
  # * :member => Current Member record
  render_on :view_projects_settings_members_table_row, :partial => 'hooks/view_projects_settings_members_table_row'

  # Renders table headers to update the member's billing rate
  # Context:
  # * :project => Current project
  render_on :view_projects_settings_members_table_header, :partial => 'hooks/view_projects_settings_members_table_header'
    
  # TODO: implement  model_project_copy_before_save
end