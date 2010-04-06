require 'redmine'

require 'dispatcher'
 
require 'query_patch'
require 'issue_patch'
require 'version_patch'

Dispatcher.to_prepare do
    require_dependency 'version'
    require_dependency 'issue'
    require_dependency 'issue_relation'
    require_dependency 'version'

    Issue::SAFE_ATTRIBUTES << "story_points" if Issue.const_defined? "SAFE_ATTRIBUTES"
    Issue::SAFE_ATTRIBUTES << "remaining_hours" if Issue.const_defined? "SAFE_ATTRIBUTES"

    Query.send(:include, QueryPatch) unless Query.included_modules.include? QueryPatch
    Issue.send(:include, IssuePatch) unless Issue.included_modules.include? IssuePatch
    Version.send(:include, VersionPatch) unless Version.included_modules.include? VersionPatch
end

require_dependency 'backlogs_layout_hooks'

Redmine::Plugin.register :redmine_backlogs do
    name 'Redmine Scrum Plugin'
    author 'Mark Maglana, friflaj'
    description 'Scrum plugin for Redmine'
    version '2.1 unstable'

    settings :default => { :story_trackers => nil, :task_tracker => nil }, :partial => 'settings/backlogs_settings'

    project_module :backlogs do
        permission :manage_backlog,
                   { :backlogs => [ :wiki_page,
                                    :wiki_page_edit,
                                    :story_points,
                                    :rename,
                                    :noconfig,
                                    :jsvariables,
                                    :index,
                                    :reorder,
                                    :sprint_date,
                                    :select_sprint,
                                    :update,
                                    :burndown ],
                    :stories => [ :index,
                                  :new,
                                  :create,
                                  :update ]
                  }
    end

    menu :project_menu, :backlogs, { :controller => 'backlogs', :action => 'index' }, :caption => 'Backlog', :after => :issues, :param => :project_id
end


