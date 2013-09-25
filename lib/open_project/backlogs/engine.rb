require 'acts_as_silent_list'
#require 'openproject-nissue'

module OpenProject::Backlogs
  class Engine < ::Rails::Engine
    engine_name :openproject_backlogs

    def self.settings
      { :default => { "story_types"  => nil,
                      "task_type"    => nil,
                      "card_spec"       => nil
      },
      :partial => 'shared/settings' }
    end

    config.autoload_paths += Dir["#{config.root}/lib/"]

    initializer 'backlogs.precompile_assets' do
      Rails.application.config.assets.precompile += %w( backlogs.css backlogs.js master_backlogs.css taskboard.css)
    end

    config.before_configuration do |app|
      # This is required for the routes to be loaded first
      # as the routes should be prepended so they take precedence over the core.
      app.config.paths['config/routes'].unshift File.join(File.dirname(__FILE__), "..", "..", "..", "config", "routes.rb")
    end

    initializer "remove_duplicate_backlogs_routes", :after => "add_routing_paths" do |app|
      # removes duplicate entry from app.routes_reloader
      # As we prepend the plugin's routes to the load_path up front and rails
      # adds all engines' config/routes.rb later, we have double loaded the routes
      # This is not harmful as such but leads to duplicate routes which decreases performance
      app.routes_reloader.paths.uniq!
    end

    initializer 'backlogs.register_test_paths' do |app|
      app.config.plugins_to_test_paths << self.root
    end

    # adds our factories to factory girl's load path
    initializer "backlogs.register_factories", :after => "factory_girl.set_factory_paths" do |app|
      FactoryGirl.definition_file_paths << File.expand_path(self.root.to_s + '/spec/factories') if defined?(FactoryGirl)
    end

    config.to_prepare do

      # TODO: avoid this dirty hack necessary to prevent settings method getting lost after reloading
      Setting.create_setting("plugin_openproject_backlogs", {'default' => Engine.settings[:default], 'serialized' => true})
      Setting.create_setting_accessors("plugin_openproject_backlogs")

      require_dependency 'work_package'
      require_dependency 'task'
      require_dependency 'acts_as_silent_list'

      if WorkPackage.const_defined? "SAFE_ATTRIBUTES"
        WorkPackage::SAFE_ATTRIBUTES << "story_points"
        WorkPackage::SAFE_ATTRIBUTES << "remaining_hours"
        WorkPackage::SAFE_ATTRIBUTES << "position"
      else
        WorkPackage.safe_attributes "story_points", "remaining_hours", "position"
      end

      require_dependency 'open_project/backlogs/work_package_view'
      require_dependency 'open_project/backlogs/work_package_form'

      # 'require_dependency' reloads the class with every request
      # in development mode which
      # would duplicate the registered view listeners
      require 'open_project/backlogs/hooks'

      require_dependency 'open_project/backlogs/patches'
      require_dependency 'open_project/backlogs/patches/permitted_params_patch'
      require_dependency 'open_project/backlogs/patches/work_package_patch'
      require_dependency 'open_project/backlogs/patches/issue_status_patch'
      require_dependency 'open_project/backlogs/patches/my_controller_patch'
      require_dependency 'open_project/backlogs/patches/project_patch'
      require_dependency 'open_project/backlogs/patches/projects_controller_patch'
      require_dependency 'open_project/backlogs/patches/projects_helper_patch'
      require_dependency 'open_project/backlogs/patches/query_patch'
      require_dependency 'open_project/backlogs/patches/user_patch'
      require_dependency 'open_project/backlogs/patches/version_controller_patch'
      require_dependency 'open_project/backlogs/patches/version_patch'

      unless Redmine::Plugin.registered_plugins.include?(:openproject_backlogs)
        Redmine::Plugin.register :openproject_backlogs do
          name 'OpenProject Backlogs'
          author 'relaxdiego, friflaj, Finn GmbH'
          description 'A plugin for agile teams'

          url 'https://www.openproject.org/projects/plugin-backlogs'
          author_url 'http://www.finn.de/'

          version OpenProject::Backlogs::VERSION

          requires_openproject ">= 3.0.0pre7"

          Redmine::AccessControl.permission(:edit_project).actions << "projects/project_issue_statuses"
          Redmine::AccessControl.permission(:edit_project).actions << "projects/rebuild_positions"

          settings Engine.settings

          project_module :backlogs do
            # SYNTAX: permission :name_of_permission, { :controller_name => [:action1, :action2] }

            # Master backlog permissions
            permission :view_master_backlog, {
              :rb_master_backlogs  => :index,
              :rb_sprints          => [:index, :show],
              :rb_wikis            => :show,
              :rb_stories          => [:index, :show],
              :rb_queries          => :show,
              :rb_server_variables => :show,
              :rb_burndown_charts  => :show,
              :work_package_boxes  => :show
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
                                                  :work_package_boxes => [:edit, :update] }

            # Task permissions
            # :show_tasks and :list_tasks are implicit in :view_sprints
            permission :create_tasks,           { :rb_tasks => [:new, :create]  }
            permission :update_tasks,           { :rb_tasks => [:edit, :update],
                                                  :work_package_boxes => [:edit, :update] }

            # Impediment permissions
            # :show_impediments and :list_impediments are implicit in :view_sprints
            permission :create_impediments,     { :rb_impediments => [:new, :create]  }
            permission :update_impediments,     { :rb_impediments => [:edit, :update],
                                                  :work_package_boxes => [:edit, :update] }
          end

          menu :project_menu,
            :backlogs,
            {:controller => '/rb_master_backlogs', :action => :index},
            :caption => :project_module_backlogs,
            :before => :calendar,
            :param => :project_id,
            :if => proc { not(User.current.respond_to?(:impaired?) and User.current.impaired?) }

        end
      end

    end

    config.after_initialize do
      # We are overwriting versions/_form.html.erb so our view must be found first
      VersionsController.view_paths.unshift("#{config.root}/app/views")
    end
  end
end
