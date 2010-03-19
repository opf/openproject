require 'redmine'

require_dependency 'backlogs_layout_hooks'

Redmine::Plugin.register :redmine_backlogs do
    name 'Redmine Scrum Plugin'
    author 'friflaj'
    description 'Scrum plugin for Redmine'
    version '0.0.1'

    settings :default => { :story_tracker => nil }, :partial => 'settings/backlogs_settings'

    project_module :backlogs do
        permission :manage_backlog, :backlogs => [:rename, :index, :reorder, :sprint_date, :select_sprint]
    end

    menu :project_menu, :backlogs, { :controller => 'backlogs', :action => 'index' }, :caption => 'Backlog', :after => :issues, :param => :project_id
end
