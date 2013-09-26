# Hooks to attach to the OpenProject action menu.
class OpenProject::Costs::Hooks::WorkPackageActionMenuHook < Redmine::Hook::ViewListener
  render_on :view_issues_show_action_menu, :partial => 'hooks/view_work_package_show_action_menu'
end
