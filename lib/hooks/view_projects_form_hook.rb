class Hooks::ViewProjectsFormHook < Redmine::Hook::ViewListener
  render_on :view_projects_form,
            :partial => 'hooks/timelines/view_projects_form'

end
