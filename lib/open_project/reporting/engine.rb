module OpenProject::Reporting
  class Engine < ::Rails::Engine
    engine_name :openproject_reporting

    # def self.settings
    config.before_configuration do |app|
      # This is required for the routes to be loaded first
      # as the routes should be prepended so they take precedence over the core.
      app.config.paths['config/routes'].unshift File.join(File.dirname(__FILE__), "..", "..", "..", "config", "routes.rb")
    end

    config.autoload_paths += Dir["#{config.root}/lib/"]

    initializer "reporting.register_hooks" do
      # don't use require_dependency to not reload hooks in
      # development mode
      require 'open_project/reporting/hooks'
    end

    initializer "reporting.remove_duplicate_routes", :after => "add_routing_paths" do |app|
      # removes duplicate entry from app.routes_reloader
      # As we prepend the plugin's routes to the load_path up front and rails
      # adds all engines' config/routes.rb later, we have double loaded the routes
      # This is not harmful as such but leads to duplicate routes which decreases performance
      app.routes_reloader.paths.uniq!
    end

    initializer 'reporting.register_test_paths' do |app|
      app.config.plugins_to_test_paths << self.root
    end

    # add our factories to factory girl's load path
    initializer "reporting.register_factories", :after => "factory_girl.set_factory_paths" do |app|
      FactoryGirl.definition_file_paths << File.expand_path(self.root.to_s + '/spec/factories') if defined?(FactoryGirl)
    end

    initializer 'reporting.append_migrations' do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    config.to_prepare do
      require_dependency 'report/walker'
      require_dependency 'report/transformer'
      require_dependency 'widget/sortable_init'
      require_dependency 'widget/simple_table'
      require_dependency 'widget/entry_table'
      require_dependency 'widget/settings_patch'
      require_dependency 'open_project/reporting/patches/timelog_controller_patch'
      require_dependency 'open_project/reporting/patches/costlog_controller_patch'

      unless Redmine::Plugin.registered_plugins.include?(:openproject_reporting)
        Redmine::Plugin.register :openproject_reporting do
          name 'OpenProject Reporting'
          author 'Finn GmbH'
          description 'The reporting plugin provides extended reporting functionality for OpenProject including Cost Reports.'

          url 'https://www.openproject.org/projects/plugin-reporting'
          author_url 'https://www.finn.de'
          version OpenProject::Reporting::VERSION

          requires_openproject ">= 3.0.0pre30"

          view_actions = [:index, :show, :drill_down, :available_values, :display_report_list]
          edit_actions = [:create, :update, :rename, :delete]

          #register reporting_module including permissions
          project_module :reporting_module do
            permission :save_cost_reports, {:cost_reports => edit_actions}
            permission :save_private_cost_reports, {:cost_reports => edit_actions}
          end

          #register additional permissions for viewing time and cost entries through the CostReportsController
          view_actions.each do |action|
            Redmine::AccessControl.permission(:view_time_entries).actions << "cost_reports/#{action}"
            Redmine::AccessControl.permission(:view_own_time_entries).actions << "cost_reports/#{action}"
            Redmine::AccessControl.permission(:view_cost_entries).actions << "cost_reports/#{action}"
            Redmine::AccessControl.permission(:view_own_cost_entries).actions << "cost_reports/#{action}"
          end

          #menu extensions
          menu :top_menu, :cost_reports_global, {:controller => 'cost_reports', :action => 'index', :project_id => nil},
            :caption => :cost_reports_title,
            :if => Proc.new {
              ( User.current.allowed_to?(:view_time_entries, nil, :global => true) ||
                User.current.allowed_to?(:view_own_time_entries, nil, :global => true) ||
                User.current.allowed_to?(:view_cost_entries, nil, :global => true) ||
                User.current.allowed_to?(:view_own_cost_entries, nil, :global => true)
              )
            }

          menu :project_menu, :cost_reports,
               {:controller => 'cost_reports', :action => 'index'},
               :param => :project_id,
               :after => :cost_objects,
               :caption => :cost_reports_title,
               :if => Proc.new { |project| project.module_enabled?(:reporting_module) }
        end
      end
    end
  end
end
