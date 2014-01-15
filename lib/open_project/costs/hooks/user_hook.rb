class OpenProject::Costs::Hooks::UserHook < Redmine::Hook::ViewListener
  render_on :users_show_head,
            partial: 'hooks/costs/activity_index_head'
end
