class ViewProjectsShowSidebarBottomHook < Redmine::Hook::ViewListener
  render_on :view_projects_show_sidebar_bottom, :partial => 'hooks/view_projects_show_sidebar_bottom_hook'
end
