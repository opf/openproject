require 'redmine'
require 'dispatcher'

Dispatcher.to_prepare do
  require_dependency 'issue'

  Issue::SAFE_ATTRIBUTES << "story_points" if Issue.const_defined? "SAFE_ATTRIBUTES"
  Issue::SAFE_ATTRIBUTES << "remaining_hours" if Issue.const_defined? "SAFE_ATTRIBUTES"
  Issue::SAFE_ATTRIBUTES << "position" if Issue.const_defined? "SAFE_ATTRIBUTES"

  require_dependency 'backlogs_query_patch'
  require_dependency 'backlogs_issue_patch'
  require_dependency 'backlogs_version_patch'
  require_dependency 'backlogs_project_patch'
  require_dependency 'backlogs_user_patch'
  require_dependency 'backlogs_my_controller_patch'
end

require_dependency 'backlogs_hooks'

Redmine::Plugin.register :redmine_backlogs do
  name 'Redmine Backlogs Plugin'
  author 'relaxdiego, friflaj'
  description 'A plugin for scrum/agile teams'
  version 'v0.2.1'

  settings :default => { :story_trackers => nil, :task_tracker => nil, :card_spec => nil }, :partial => 'settings/backlogs_settings'

  project_module :backlogs do
    permission :manage_backlog,
           { :backlogs => [
                :wiki_page_edit,
                :story_points,
                :rename,
                :show,
                :burndown,
                :jsvariables,
                :reorder,
                :sprint_date,
                :index,
                :update ],

              :stories => [
                :new,
                :create,
                :update ],

              :tasks => [
                :update,
                :new,
                :create ],
              
              :charts => [
                :show ],
                
              :server_variables => [
                :index]
          }

    permission :view_backlog,
           { :backlogs => [
                :wiki_page,
                :noconfig,
                :index,
                :show,
                :select_issues,
                :taskboard_cards,
                :product_backlog_cards,
                :calendar,
                :burndown ],
              :stories => [ :index ],
              :tasks => [ :index ],
              :charts => [ :show ],
              :server_variables => [
                :index]
          }
    permission :view_statistics, { :backlogs_global => [ :statistics ] }
  end

  menu :project_menu, :backlogs, { :controller => 'backlogs', :action => 'index' }, :caption => :label_backlogs, :after => :issues, :param => :project_id
  menu :application_menu, :backlogs, { :controller => 'backlogs_global', :action => 'statistics'}, :caption => :label_scrum_statistics
end