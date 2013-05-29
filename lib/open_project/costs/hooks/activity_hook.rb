class OpenProject::Costs::Hooks < Redmine::Hook::ViewListener
  render_on :activity_index_head,
            :partial => 'hooks/activity_index_head'
end
