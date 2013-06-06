class Timelines::Hooks::ActivityIndexHeadHook < Redmine::Hook::ViewListener
  render_on :activity_index_head, :partial => 'hooks/timelines/activity_index_head'
end
