require 'redmine'
require 'dispatcher'
require 'acts_as_silent_list'

Dispatcher.to_prepare do
  require_dependency 'issue'
  require_dependency 'task'

  if Issue.const_defined? "SAFE_ATTRIBUTES"
    Issue::SAFE_ATTRIBUTES << "story_points"
    Issue::SAFE_ATTRIBUTES << "remaining_hours"
    Issue::SAFE_ATTRIBUTES << "position"
  else
    Issue.safe_attributes "story_points", "remaining_hours", "position"
  end

  require_dependency 'backlogs/issue_view'
  require_dependency 'backlogs/issue_form'

  require_dependency 'backlogs/hooks'

  require_dependency 'backlogs/patches/issue_patch'
  require_dependency 'backlogs/patches/issue_status_patch'
  require_dependency 'backlogs/patches/my_controller_patch'
  require_dependency 'backlogs/patches/project_patch'
  require_dependency 'backlogs/patches/projects_controller_patch'
  require_dependency 'backlogs/patches/projects_helper_patch'
  require_dependency 'backlogs/patches/query_patch'
  require_dependency 'backlogs/patches/user_patch'
  require_dependency 'backlogs/patches/version_controller_patch'
  require_dependency 'backlogs/patches/version_patch'
end

Redmine::Plugin.register :backlogs do
  name 'ChiliProject Backlogs'
  author 'relaxdiego, friflaj, Gregor Schmidt, Jens Ulferts'
  description 'A plugin for agile teams'

  url 'http://github.com/finnlabs/chiliproject_backlogs'
  author_url 'http://www.finn.de/'

  version '1.2.1'

  requires_redmine_plugin 'chiliproject_nissue', '1.0.0'

  Redmine::AccessControl.permission(:edit_project).actions << "projects/project_issue_statuses"
  Redmine::AccessControl.permission(:edit_project).actions << "projects/rebuild_positions"


  settings :default => {
                         "story_trackers"  => nil,
                         "task_tracker"    => nil,
                         "card_spec"       => nil
                       },
           :partial => 'shared/settings'

  project_module :backlogs do
    # SYNTAX: permission :name_of_permission, { :controller_name => [:action1, :action2] }

    # Master backlog permissions
    permission :view_master_backlog, {
                                       :rb_master_backlogs  => :show,
                                       :rb_sprints          => [:index, :show],
                                       :rb_wikis            => :show,
                                       :rb_stories          => [:index, :show],
                                       :rb_queries          => :show,
                                       :rb_server_variables => :show,
                                       :rb_burndown_charts  => :show,
                                       :issue_boxes         => :show
                                     }

    permission :view_taskboards,     {
                                       :rb_taskboards       => :show,
                                       :rb_sprints          => :show,
                                       :rb_stories          => [:index, :show],
                                       :rb_tasks            => [:index, :show],
                                       :rb_impediments      => [:index, :show],
                                       :rb_wikis            => :show,
                                       :rb_server_variables => :show,
                                       :rb_burndown_charts  => :show
                                     }

    # Sprint permissions
    # :show_sprints and :list_sprints are implicit in :view_master_backlog permission
    permission :update_sprints,      {
                                        :rb_sprints => [:edit, :update],
                                        :rb_wikis   => [:edit, :update]
                                      }

    # Story permissions
    # :show_stories and :list_stories are implicit in :view_master_backlog permission
    permission :create_stories,         { :rb_stories => :create }
    permission :update_stories,         { :rb_stories => :update,
                                          :issue_boxes => [:edit, :update] }

    # Task permissions
    # :show_tasks and :list_tasks are implicit in :view_sprints
    permission :create_tasks,           { :rb_tasks => [:new, :create]  }
    permission :update_tasks,           { :rb_tasks => [:edit, :update],
                                          :issue_boxes => [:edit, :update] }

    # Impediment permissions
    # :show_impediments and :list_impediments are implicit in :view_sprints
    permission :create_impediments,     { :rb_impediments => [:new, :create]  }
    permission :update_impediments,     { :rb_impediments => [:edit, :update],
                                          :issue_boxes => [:edit, :update] }
  end

  menu :project_menu,
       :backlogs,
       {:controller => :rb_master_backlogs, :action => :show},
       :caption => :project_module_backlogs,
       :before => :calendar,
       :param => :project_id,
       :if => proc { not(User.current.respond_to?(:impaired?) and User.current.impaired?) }
end
