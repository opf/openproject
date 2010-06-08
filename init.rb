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
    require_dependency 'project'

    Issue::SAFE_ATTRIBUTES << "story_points" if Issue.const_defined? "SAFE_ATTRIBUTES"
    Issue::SAFE_ATTRIBUTES << "remaining_hours" if Issue.const_defined? "SAFE_ATTRIBUTES"
    Issue::SAFE_ATTRIBUTES << "position" if Issue.const_defined? "SAFE_ATTRIBUTES"

    Query.send(:include, QueryPatch) unless Query.included_modules.include? QueryPatch
    Issue.send(:include, IssuePatch) unless Issue.included_modules.include? IssuePatch
    Version.send(:include, VersionPatch) unless Version.included_modules.include? VersionPatch
    Project.send(:include, ProjectPatch) unless Project.included_modules.include? ProjectPatch
end

require_dependency 'backlogs_hooks'

Redmine::Plugin.register :redmine_backlogs do
    name 'Redmine Scrum Plugin'
    author 'Mark Maglana, friflaj'
    description 'Scrum plugin for Redmine'
    version '2.1 unstable'

    settings :default => { :story_trackers => nil, :task_tracker => nil, :card_spec => nil }, :partial => 'settings/backlogs_settings'

    project_module :backlogs do
        permission :manage_backlog,
                   { :backlogs => [ :wiki_page_edit,
                                    :story_points,
                                    :rename,
                                    :jsvariables,
                                    :reorder,
                                    :sprint_date,
                                    :update ],
                    :stories => [ :new,
                                  :create,
                                  :update ],
                    :tasks => [   :update,
                                  :new,
                                  :create ],
                  }
        permission :view_backlog,
                   { :backlogs => [ :wiki_page,
                                    :noconfig,
                                    :index,
                                    :show,
                                    :select_issues,
                                    :taskboard_cards,
                                    :product_backlog_cards,
                                    :calendar,
                                    :burndown ],
                    :stories => [ :index ],
                    :tasks => [   :index ],
                  }
        permission :view_statistics, { :backlogs_global => [ :statistics ] }
    end

    menu :project_menu, :backlogs, { :controller => 'backlogs', :action => 'index' }, :caption => :label_backlogs, :after => :issues, :param => :project_id
    menu :application_menu, :backlogs, { :controller => 'backlogs_global', :action => 'statistics'}, :caption => :label_scrum_statistics
end


