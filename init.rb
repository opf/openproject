require 'redmine'

require 'dispatcher'
 
require 'query_patch'

Dispatcher.to_prepare do
    require_dependency 'version'
    require_dependency 'issue'
    Issue::SAFE_ATTRIBUTES << "story_points" if Issue.const_defined? "SAFE_ATTRIBUTES"
    Issue::SAFE_ATTRIBUTES << "position" if Issue.const_defined? "SAFE_ATTRIBUTES"
    Issue::SAFE_ATTRIBUTES << "remaining_hours" if Issue.const_defined? "SAFE_ATTRIBUTES"

    Query.send(:include, QueryPatch) unless Query.included_modules.include? QueryPatch
end

require_dependency 'backlogs_layout_hooks'

Redmine::Plugin.register :redmine_backlogs do
    name 'Redmine Scrum Plugin'
    author 'friflaj'
    description 'Scrum plugin for Redmine'
    version '0.0.1'

    settings :default => { :story_tracker => nil, :task_tracker => nil }, :partial => 'settings/backlogs_settings'

    project_module :backlogs do
        permission :manage_backlog, :backlogs => [:wiki_page, :story_points, :rename, :index, :reorder, :sprint_date, :select_sprint]
    end

    menu :project_menu, :backlogs, { :controller => 'backlogs', :action => 'index' }, :caption => 'Backlog', :after => :issues, :param => :project_id
end


