#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2010-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::GlobalRoles
  class Engine < ::Rails::Engine
    engine_name :openproject_global_roles

    config.autoload_paths += Dir["#{config.root}/lib/"]

    spec = Bundler.environment.specs['openproject-global_roles'][0]
    initializer 'global_roles.register_plugin' do
      require_dependency 'open_project/global_roles/patches/permission_patch'

      Redmine::Plugin.register :openproject_global_roles do
        name 'OpenProject Global Roles'
        author ((spec.authors.kind_of? Array) ? spec.authors[0] : spec.authors)
        author_url "http://finn.de"
        description spec.description
        version spec.version
        url spec.homepage

        requires_openproject ">= 3.0.0pre21"

        Redmine::AccessControl.permission(:add_project).global = true
      end
    end

    initializer 'global_roles.precompile_assets' do
      Rails.application.config.assets.precompile += %w(global_roles.css global_roles.js)
    end

    # adds our factories to factory girl's load path
    initializer "global_roles.register_factories", :after => "factory_girl.set_factory_paths" do |app|
      FactoryGirl.definition_file_paths << File.expand_path(self.root.to_s + '/spec/factories') if defined?(FactoryGirl)
    end

    initializer 'global_roles.register_test_paths' do |app|
      app.config.plugins_to_test_paths << self.root
    end

    config.before_configuration do |app|
      # This is required for the routes to be loaded first
      # as the routes should be prepended so they take precedence over the core.
      app.config.paths['config/routes'].unshift File.join(File.dirname(__FILE__), "..", "..", "..", "config", "routes.rb")
    end

    initializer "global_roles.remove_duplicate_routes", :after => "add_routing_paths" do |app|
      # removes duplicate entry from app.routes_reloader
      # As we prepend the plugin's routes to the load_path up front and rails
      # adds all engines' config/routes.rb later, we have double loaded the routes
      # This is not harmful as such but leads to duplicate routes which decreases performance
      app.routes_reloader.paths.uniq!
    end


    config.to_prepare do
      require_dependency 'open_project/global_roles/patches'

      # lib patches
      require_dependency 'open_project/global_roles/patches/access_control_patch'
      require_dependency 'open_project/global_roles/patches/permission_patch'

      # Model Patches
      require_dependency 'open_project/global_roles/patches/principal_patch'
      require_dependency 'open_project/global_roles/patches/role_patch'
      require_dependency 'open_project/global_roles/patches/user_patch'

      # Controller Patches
      require_dependency 'open_project/global_roles/patches/roles_controller_patch'
      require_dependency 'open_project/global_roles/patches/users_controller_patch'

      # Helper Patches
      require_dependency 'open_project/global_roles/patches/roles_helper_patch'
      require_dependency 'open_project/global_roles/patches/users_helper_patch'

      User.register_allowance_evaluator OpenProject::GlobalRoles::PrincipalAllowanceEvaluator::Global
    end
  end
end


