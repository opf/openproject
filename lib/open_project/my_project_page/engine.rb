#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'rails/engine'

module OpenProject::MyProjectPage
  class Engine < ::Rails::Engine
    engine_name :openproject_my_project_page


    config.autoload_paths += Dir["#{config.root}/lib/"]

    spec = Bundler.environment.specs['openproject-my_project_page'][0]
    initializer 'my_project_page.register_plugin' do
      Redmine::Plugin.register :openproject_my_project_page do

        name 'OpenProject MyProjectPage'
        author ((spec.authors.kind_of? Array) ? spec.authors[0] : spec.authors)
        author_url spec.homepage
        description spec.description
        version spec.version
        url 'https://www.openproject.org/projects/plugin-my_project_page'

        requires_openproject ">= 3.0.0pre9"

        project_module :my_project_page do
          # add plugin-specific configuration here (e.g. add permissions)
          permission :view_project, {:meetings => [:new, :create, :copy]}, :require => :member

          #TODO translate these permissions into the new syntax
          Redmine::AccessControl.permission(:view_project).actions << "my_projects_overviews/index" <<
              "my_projects_overviews/show_all_members"
          Redmine::AccessControl.permission(:edit_project).actions << "my_projects_overviews/page_layout" <<
              "my_projects_overviews/add_block" <<
              "my_projects_overviews/remove_block" <<
              "my_projects_overviews/update_custom_element" <<
              "my_projects_overviews/order_blocks" <<
              "my_projects_overviews/destroy_attachment"
        end

      end
    end

    initializer 'my_project_page.precompile_assets' do |app|
      app.config.assets.precompile += ["my_projects_overview.css"]
    end

    initializer 'my_project_page.register_path_to_rspec' do |app|
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
    initializer "my_project_page.register_factories", :after => "factory_girl.set_factory_paths" do |app|
      FactoryGirl.definition_file_paths << File.expand_path(self.root.to_s + '/spec/factories') if defined?(FactoryGirl)
    end

    initializer "my_project_page.register_hooks" do
      require 'open_project/my_project_page/hooks'
    end

    config.to_prepare do


      # load classes so that all User.before_destroy filters are loaded
      #require_dependency 'my_project_page'


    end
  end
end
