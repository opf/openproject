require_dependency 'open_project/costs/patches/i18n_patch'

module OpenProject::Costs
  class Engine < ::Rails::Engine
    engine_name :openproject_costs

    def self.settings
      { :default => { 'costs_currency' => 'EUR',
                      'costs_currency_format' => '%n %u' },
        :partial => 'settings/openproject_costs' }
    end

    initializer "costs.register_hooks" do
      require 'open_project/costs/hooks'
      require 'open_project/costs/hooks/issue_hook'
      require 'open_project/costs/hooks/project_hook'
    end

    config.autoload_paths += Dir["#{config.root}/lib/"]

    initializer 'costs.precompile_assets' do
      Rails.application.config.assets.precompile += %w(costs.css costs.js)
    end

    # adds our factories to factory girl's load path
    initializer "costs.register_factories", :after => "factory_girl.set_factory_paths" do |app|
      FactoryGirl.definition_file_paths << File.expand_path(self.root.to_s + '/spec/factories') if defined?(FactoryGirl)
    end

    initializer 'costs.register_test_paths' do |app|
      app.config.plugins_to_test_paths << self.root
    end

    initializer 'costs.register_observers' do |app|
      # Observers
      ActiveRecord::Base.observers.push :rate_observer, :default_hourly_rate_observer, :costs_issue_observer
    end

    config.before_configuration do |app|
      # This is required for the routes to be loaded first
      # as the routes should be prepended so they take precedence over the core.
      app.config.paths['config/routes'].unshift File.join(File.dirname(__FILE__), "..", "..", "..", "config", "routes.rb")
    end

    initializer "costs.remove_duplicate_routes", :after => "add_routing_paths" do |app|
      # removes duplicate entry from app.routes_reloader
      # As we prepend the plugin's routes to the load_path up front and rails
      # adds all engines' config/routes.rb later, we have double loaded the routes
      # This is not harmful as such but leads to duplicate routes which decreases performance
      app.routes_reloader.paths.uniq!
    end

    config.to_prepare do

      # TODO: avoid this dirty hack necessary to prevent settings method getting lost after reloading
      Setting.create_setting("plugin_openproject_costs", {'default' => Engine.settings[:default], 'serialized' => true})
      Setting.create_setting_accessors("plugin_openproject_costs")

      require 'open_project/costs/patches'

      # Model Patches
      require_dependency 'open_project/costs/patches/issue_patch'
      require_dependency 'open_project/costs/patches/project_patch'
      require_dependency 'open_project/costs/patches/query_patch'
      require_dependency 'open_project/costs/patches/user_patch'
      require_dependency 'open_project/costs/patches/time_entry_patch'
      require_dependency 'open_project/costs/patches/version_patch'
      require_dependency 'open_project/costs/patches/permitted_params_patch'

      # Controller Patchesopen_project/costs/patches/
      require_dependency 'open_project/costs/patches/application_controller_patch'
      require_dependency 'open_project/costs/patches/issues_controller_patch'
      require_dependency 'open_project/costs/patches/timelog_controller_patch'
      require_dependency 'open_project/costs/patches/projects_controller_patch'

      # Helper Patches
      require_dependency 'open_project/costs/patches/application_helper_patch'
      require_dependency 'open_project/costs/patches/users_helper_patch'
      require_dependency 'open_project/costs/patches/issues_helper_patch'

      require_dependency 'open_project/costs/patches/issue_observer'

      # loading the class so that acts_as_journalized gets registered
      VariableCostObject

      unless Redmine::Plugin.registered_plugins.include?(:openproject_costs)
        Redmine::Plugin.register :openproject_costs do

          name 'Costs Plugin'
          author 'Finn GmbH'
          author_url 'http://finn.de/team'
          description 'The costs plugin provides basic cost management functionality for OpenProject.'

          version OpenProject::Costs::VERSION

          settings Engine.settings

          # register our custom permissions
          project_module :costs_module do
            permission :view_own_hourly_rate, {}
            permission :view_hourly_rates, {}

            permission :edit_own_hourly_rate, {:hourly_rates => [:set_rate, :edit, :update]},
                                              :require => :member
            permission :edit_hourly_rates, {:hourly_rates => [:set_rate, :edit, :update]},
                                           :require => :member
            permission :view_cost_rates, {} # cost item values

            permission :log_own_costs, { :costlog => [:new, :create] },
                                       :require => :loggedin
            permission :log_costs, {:costlog => [:new, :create]},
                                   :require => :member

            permission :edit_own_cost_entries, {:costlog => [:edit, :update, :destroy]},
                                               :require => :loggedin
            permission :edit_cost_entries, {:costlog => [:edit, :update, :destroy]},
                                           :require => :member

            permission :block_tickets, {}, :require => :member
            permission :view_cost_objects, {:cost_objects => [:index, :show]}

            permission :view_cost_entries, { :cost_objects => [:index, :show] }
            permission :view_own_cost_entries, { :cost_objects => [:index, :show] }

            permission :edit_cost_objects, {:cost_objects => [:index, :show, :edit, :update, :destroy, :new, :create]}
          end

          # register additional permissions for the time log
          project_module :time_tracking do
            permission :view_own_time_entries, {:timelog => [:details, :report]}
          end

          view_time_entries = Redmine::AccessControl.permission(:view_time_entries)
          view_time_entries.actions << "cost_reports/index"

          # Menu extensions
          menu :top_menu,
               :cost_types,
               {:controller => 'cost_types', :action => 'index'},
               :caption => :cost_types_title,
               :if => Proc.new { User.current.admin? }

          menu :project_menu,
               :cost_objects,
               {:controller => 'cost_objects', :action => 'index'},
               :param => :project_id,
               :before => :settings,
               :caption => :cost_objects_title

          menu :project_menu,
               :new_budget,
               {:action => 'new', :controller => 'cost_objects' },
               :param => :project_id,
               :caption => :label_cost_object_new,
               :parent => :cost_objects

          menu :project_menu,
               :show_all,
               {:action => 'index', :controller => 'cost_objects' },
               :param => :project_id,
               :caption => :label_view_all_cost_objects,
               :parent => :cost_objects
        end
      end
    end

    config.after_initialize do
      # We are overwriting issues/_action_menu.html.erb so our view must be found first
      IssuesController.view_paths.unshift("#{config.root}/app/views")
    end

  end
end


