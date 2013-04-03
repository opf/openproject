module OpenProject::Backlogs
  class Engine < ::Rails::Engine
    engine_name :openproject_backlogs

    def self.settings
      { :default => { "story_trackers"  => nil,
                      "task_tracker"    => nil,
                      "card_spec"       => nil
                    },
        :partial => 'shared/settings' }
    end

    config.autoload_paths += Dir["#{config.root}/lib/"]

    initializer 'backlogs.precompile_assets' do
      Rails.application.config.assets.precompile += %w( backlogs.css backlogs.js )
    end

    config.to_prepare do

      # TODO: avoid this dirty hack necessary to prevent settings method getting lost after reloading
      Setting.create_setting("plugin_openproject_backlogs", {'default' => Engine.settings[:default], 'serialized' => true})
      Setting.create_setting_accessors("plugin_openproject_backlogs")

      require_dependency 'issue'
      require_dependency 'task'
      require_dependency 'acts_as_silent_list'

      if Issue.const_defined? "SAFE_ATTRIBUTES"
        Issue::SAFE_ATTRIBUTES << "story_points"
        Issue::SAFE_ATTRIBUTES << "remaining_hours"
        Issue::SAFE_ATTRIBUTES << "position"
      else
        Issue.safe_attributes "story_points", "remaining_hours", "position"
      end

      require_dependency 'open_project/backlogs/issue_view'
      require_dependency 'open_project/backlogs/issue_form'

      # 'require_dependency' reloads the class with every request
      # in development mode which
      # would duplicate the registered view listeners
      require 'open_project/backlogs/hooks'

      require_dependency 'open_project/backlogs/patches'
      require_dependency 'open_project/backlogs/patches/issue_patch'
      require_dependency 'open_project/backlogs/patches/issue_status_patch'
      require_dependency 'open_project/backlogs/patches/my_controller_patch'
      require_dependency 'open_project/backlogs/patches/project_patch'
      require_dependency 'open_project/backlogs/patches/projects_controller_patch'
      require_dependency 'open_project/backlogs/patches/projects_helper_patch'
      require_dependency 'open_project/backlogs/patches/query_patch'
      require_dependency 'open_project/backlogs/patches/user_patch'
      require_dependency 'open_project/backlogs/patches/version_controller_patch'
      require_dependency 'open_project/backlogs/patches/version_patch'

    end

    config.after_initialize do

      # We are overwriting versions/_form.html.erb so our view must be found first
      VersionsController.view_paths.unshift("#{config.root}/app/views")

      Redmine::Plugin.register :openproject_backlogs do
        name 'OpenProject Backlogs'
        author 'relaxdiego, friflaj, Finn GmbH'
        description 'A plugin for agile teams'

        url 'https://github.com/finnlabs/openproject_backlogs'
        author_url 'http://www.finn.de/'

        version OpenProject::Backlogs::VERSION

        #requires_redmine_plugin 'chiliproject_nissue', '1.0.0'

        Redmine::AccessControl.permission(:edit_project).actions << "projects/project_issue_statuses"
        Redmine::AccessControl.permission(:edit_project).actions << "projects/rebuild_positions"

        settings Engine.settings

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
    end
  end
end
