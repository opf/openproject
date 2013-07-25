require 'rails/engine'

module OpenProject::Meeting
  class Engine < ::Rails::Engine

    initializer 'openproject_meeting.precompile_assets' do |app|
      app.config.assets.precompile += ["openproject_meeting.css"]
    end

    initializer 'openproject_meeting.register_path_to_rspec' do |app|
      app.config.plugins_to_test_paths << self.root
    end

    config.before_configuration do |app|
      # This is required for the routes to be loaded first
      # as the routes should be prepended so they take precedence over the core.
      app.config.paths['config/routes'].unshift File.join(File.dirname(__FILE__), "..", "..", "..", "config", "routes.rb")
    end

    initializer "remove_duplicate_meeting_routes", :after => "add_routing_paths" do |app|
      # removes duplicate entry from app.routes_reloader
      # As we prepend the plugin's routes to the load_path up front and rails
      # adds all engines' config/routes.rb later, we have double loaded the routes
      # This is not harmful as such but leads to duplicate routes which decreases performance
      app.routes_reloader.paths.uniq!
    end

    # adds our factories to factory girl's load path
    initializer "meetings.register_factories", :after => "factory_girl.set_factory_paths" do |app|
      FactoryGirl.definition_file_paths << File.expand_path(self.root.to_s + '/spec/factories') if defined?(FactoryGirl)
    end

    config.to_prepare do
      require 'redmine/plugin'

      require_dependency 'open_project/meeting/hooks'
      require 'open_project/meeting/patches/project_patch'
      Project.send(:include, Patches::ProjectPatch)

      # load classes so that all User.before_destroy filters are loaded
      require_dependency 'meeting'
      require_dependency 'meeting_agenda'
      require_dependency 'meeting_minutes'
      require_dependency 'meeting_participant'

      spec = Bundler.environment.specs['openproject-meeting'][0]

      unless Redmine::Plugin.registered_plugins.include?(:openproject_meeting)
        Redmine::Plugin.register :openproject_meeting do
          name 'OpenProject Meeting'
          author ((spec.authors.kind_of? Array) ? spec.authors[0] : spec.authors)
          author_url spec.homepage
          description spec.description
          version spec.version
          url 'https://www.openproject.org/projects/plugin-meetings'

          requires_openproject ">= 3.0.0pre9"

          project_module :meetings do
            permission :create_meetings, {:meetings => [:new, :create, :copy]}, :require => :member
            permission :edit_meetings, {:meetings => [:edit, :update]}, :require => :member
            permission :delete_meetings, {:meetings => [:destroy]}, :require => :member
            permission :view_meetings, {:meetings => [:index, :show], :meeting_agendas => [:history, :show, :diff], :meeting_minutes => [:history, :show, :diff]}
            permission :create_meeting_agendas, {:meeting_agendas => [:update, :preview]}, :require => :member
            permission :close_meeting_agendas, {:meeting_agendas => [:close, :open]}, :require => :member
            permission :send_meeting_agendas_notification, {:meeting_agendas => [:notify]}, :require => :member
            permission :create_meeting_minutes, {:meeting_minutes => [:update, :preview]}, :require => :member
            permission :send_meeting_minutes_notification, {:meeting_minutes => [:notify]}, :require => :member
          end

          Redmine::Search.map do |search|
            search.register :meetings
          end

          menu :project_menu, :meetings, {:controller => 'meetings', :action => 'index'}, :caption => :project_module_meetings, :param => :project_id, :after => :wiki
          menu :project_menu, :new_meeting, {:controller => 'meetings', :action => 'new'}, :param => :project_id, :caption => :label_meeting_new, :parent => :meetings

          ActiveSupport::Inflector.inflections do |inflect|
            inflect.uncountable "meeting_minutes"
          end
        end
      end
    end
  end
end
