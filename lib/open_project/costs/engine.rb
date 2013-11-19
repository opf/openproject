module OpenProject::Costs
  class Engine < ::Rails::Engine
    engine_name :openproject_costs

    def self.settings
      { :default => { 'costs_currency' => 'EUR',
                      'costs_currency_format' => '%n %u' },
        :partial => 'settings/openproject_costs' }
    end

    initializer "costs.register_hooks" do
      require_dependency 'open_project/costs/hooks'
      require_dependency 'open_project/costs/hooks/activity_hook'
      require_dependency 'open_project/costs/hooks/work_package_hook'
      require_dependency 'open_project/costs/hooks/project_hook'
      require_dependency 'open_project/costs/hooks/work_package_action_menu'
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
      ActiveRecord::Base.observers.push :rate_observer, :default_hourly_rate_observer, :costs_work_package_observer
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

    initializer "costs.patch_i18n" do
      # This is done here instead of doing it along with the rest of the patches as
      # i18n is not unloaded between requests. Hence, placing it inside the config.to_prepare
      # block would patch i18n once for every request.
      require_dependency 'open_project/costs/patches/i18n_patch'
    end

    initializer 'costs.append_migrations' do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    config.to_prepare do

      # TODO: avoid this dirty hack necessary to prevent settings method getting lost after reloading
      Setting.create_setting("plugin_openproject_costs", {'default' => Engine.settings[:default], 'serialized' => true})
      Setting.create_setting_accessors("plugin_openproject_costs")

      require 'open_project/costs/patches'

      # Model Patches
      require_dependency 'open_project/costs/patches/work_package_patch'
      require_dependency 'open_project/costs/patches/project_patch'
      require_dependency 'open_project/costs/patches/query_patch'
      require_dependency 'open_project/costs/patches/user_patch'
      require_dependency 'open_project/costs/patches/time_entry_patch'
      require_dependency 'open_project/costs/patches/version_patch'
      require_dependency 'open_project/costs/patches/permitted_params_patch'

      # Controller Patches
      require_dependency 'open_project/costs/patches/application_controller_patch'
      require_dependency 'open_project/costs/patches/work_packages_controller_patch'
      require_dependency 'open_project/costs/patches/projects_controller_patch'

      # Helper Patches
      require_dependency 'open_project/costs/patches/application_helper_patch'
      require_dependency 'open_project/costs/patches/users_helper_patch'
      require_dependency 'open_project/costs/patches/work_packages_helper_patch'

      require_dependency 'open_project/costs/patches/work_package_observer'

      # loading the class so that acts_as_journalized gets registered
      VariableCostObject

      # TODO: this recreates the original behaviour
      # however, it might not be desirable to allow assigning of cost_object regardless of the permissions
      PermittedParams.permit(:new_work_package, :cost_object_id)

      unless Redmine::Plugin.registered_plugins.include?(:openproject_costs)
        Redmine::Plugin.register :openproject_costs do

          name 'OpenProject Costs'
          author 'Finn GmbH'
          author_url 'http://finn.de/'
          url 'https://www.openproject.org/projects/costs-plugin'
          description 'The costs plugin provides basic cost management functionality for OpenProject.'

          version OpenProject::Costs::VERSION

          settings Engine.settings

          requires_openproject ">= 3.0.0pre23"

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

            permission :view_cost_entries, { :cost_objects => [:index, :show], :costlog => [:index] }
            permission :view_own_cost_entries, { :cost_objects => [:index, :show], :costlog => [:index] }

            permission :edit_cost_objects, {:cost_objects => [:index, :show, :edit, :update, :destroy, :new, :create, :copy]}
          end

          # register additional permissions for the time log
          project_module :time_tracking do
            permission :view_own_time_entries, {:timelog => [:index, :report]}
          end


          # Menu extensions
          menu :top_menu,
               :cost_types,
               {:controller => '/cost_types', :action => 'index'},
               :caption => :cost_types_title,
               :if => Proc.new { User.current.admin? }

          menu :project_menu,
               :cost_objects,
               {:controller => '/cost_objects', :action => 'index'},
               :param => :project_id,
               :before => :settings,
               :caption => :cost_objects_title,
               :html => {:'data-icon2' => 'C'}

          menu :project_menu,
               :new_budget,
               {:controller => '/cost_objects', :action => 'new' },
               :param => :project_id,
               :caption => :label_cost_object_new,
               :parent => :cost_objects

          menu :project_menu,
               :show_all,
               {:controller => '/cost_objects', :action => 'index' },
               :param => :project_id,
               :caption => :label_view_all_cost_objects,
               :parent => :cost_objects
        end
      end
    end
  end
end


