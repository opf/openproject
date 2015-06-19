#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::Plugins
  module ActsAsOpEngine
    def self.included(base)
      base.send(:define_method, :name) do
        ActiveSupport::Inflector.demodulize(base).downcase
      end

      # Don't use the PatchRegistry for now, as the core classes doesn't notify of class loading
      # Use the old config.to_prepare method, but we can hopefully someday switch to on-demand
      # patching once the PatchRegistry works.

      # base.send(:define_method, :patch) do |target, patch|
      #   OpenProject::Plugins::PatchRegistry.register(target, patch)
      # end

      # Disable LoadDependency for the same reason
      # base.send(:define_method, :load_dependent) do |target, *dependencies|
      #   OpenProject::Plugins::LoadDependency.register(target, *dependencies)
      # end

      # Patch classes
      #
      # Looks for patches via autoloading in
      # <plugin root>/lib/openproject/<plugin name>/patches/<patched_class>_patch.rb
      # Make sure the patch module has the name the Rails autoloading expects.
      #
      # Example:
      #  patches [:IssuesController]
      # This looks for OpenProject::XlsExport::Patches::IssuesControllerPatch
      #  in openproject/xls_export/patches/issues_controller_patch.rb
      base.send(:define_method, :patches) do |patched_classes|
        plugin_module = self.class.to_s.deconstantize
        base.config.to_prepare do
          patched_classes.each do |klass_name|
            patch = "#{plugin_module}::Patches::#{klass_name}Patch".constantize
            klass = klass_name.to_s.constantize
            klass.send(:include, patch) unless klass.included_modules.include?(patch)
          end
        end
      end

      base.send(:define_method, :patch_with_namespace) do |*args|
        plugin_module = self.class.to_s.deconstantize
        base.config.to_prepare do
          klass_name = args.last
          patch = "#{plugin_module}::Patches::#{klass_name}Patch".constantize
          qualified_class_name = args.map(&:to_s).join('::')
          klass = qualified_class_name.to_s.constantize
          klass.send(:include, patch) unless klass.included_modules.include?(patch)
        end
      end

      # Define assets provided by the plugin
      base.send(:define_method, :assets) do |assets|
        base.initializer "#{engine_name}.precompile_assets" do |app|
          app.config.assets.precompile += assets.to_a
        end
      end

      # Add permitted attributes (strong_parameters)
      #
      # Useful when adding a field to an OpenProject core model. We discourage adding
      # a field to a core model, but at the moment there's no API to do this in a better way
      # and a lot of existing plugins already do it.
      #
      # See PermittedParams in OpenProject for available models
      #
      # Example:
      #  additional_permitted_attributes :user => [:registration_reason]
      base.send(:define_method, :additional_permitted_attributes) do |attributes|
        config.to_prepare do
          ::PermittedParams.send(:add_permitted_attributes, attributes)
        end
      end

      # Register a plugin with OpenProject
      #
      # Uses Gem specification for plugin name, author etc.
      #
      # gem_name:      The gem name, used for querying the gem for metadata like author
      # options:       An options Hash, at least :requires_openproject is recommended to
      #                define the minimal version of OpenProject the plugin is compatible with
      #                Another common option is :author_url.
      # block:         Pass a block to the plugin (for defining permissions, menu items and the like)
      base.send(:define_method, :register) do |gem_name, options, &block|
        base.initializer "#{engine_name}.register_plugin" do
          spec = Bundler.environment.specs[gem_name][0]

          p = Redmine::Plugin.register engine_name.to_sym do
            name spec.summary
            author spec.authors.is_a?(Array) ? spec.authors[0] : spec.authors
            description spec.description
            version spec.version
            url spec.homepage

            options.each do |name, value|
              send(name, value)
            end
          end
          p.instance_eval(&block) if p && block
        end

        # Workaround to ensure settings are available after unloading in development mode
        plugin_name = engine_name
        if options.include? :settings
          base.class_eval do
            config.to_prepare do
              Setting.create_setting("plugin_#{plugin_name}",
                                     'default' => options[:settings][:default], 'serialized' => true)
              Setting.create_setting_accessors("plugin_#{plugin_name}")
            end
          end
        end
      end

      base.send(:define_method, :add_api_path) do |path_name, &block|
        config.to_prepare do
          ::API::V3::Utilities::PathHelper::ApiV3Path.class_eval do
            singleton_class.instance_eval do
              define_method path_name, &block
            end
          end
        end
      end

      base.send(:define_method, :add_api_endpoint) do |base_endpoint, path = nil, &block|
        config.to_prepare do
          # we are expecting the base_endpoint as string for two reasons:
          # 1. it does not seem possible to pass it as constant (auto loader not ready yet)
          # 2. we can't constantize it here, because that would evaluate
          #    the API before it can be patched
          ::API::APIPatchRegistry.add_patch base_endpoint, path, &block
        end
      end

      base.send(:define_method, :extend_api_response) do |*args, &block|
        config.to_prepare do
          representer_namespace = args.map { |arg| arg.to_s.camelize }.join('::')
          representer_class     = "::API::#{representer_namespace}Representer".constantize
          representer_class.instance_eval(&block)
        end
      end

      base.send(:define_method, :allow_attribute_update) do |model, actions, attribute, &block|
        config.to_prepare do
          model_name = model.to_s.camelize
          namespace = model_name.pluralize
          Array(actions).each do |action|
            contract_class = "::API::V3::#{namespace}::#{action.to_s.camelize}Contract".constantize
            contract_class.attribute attribute, &block
          end
        end
      end

      base.class_eval do
        config.autoload_paths += Dir["#{config.root}/lib/"]

        config.before_configuration do |app|
          # This is required for the routes to be loaded first
          # as the routes should be prepended so they take precedence over the core.
          app.config.paths['config/routes'].unshift File.join(config.root, 'config', 'routes.rb')
        end

        initializer "#{engine_name}.remove_duplicate_routes", after: 'add_routing_paths' do |app|
          # removes duplicate entry from app.routes_reloader
          # As we prepend the plugin's routes to the load_path up front and rails
          # adds all engines' config/routes.rb later, we have double loaded the routes
          # This is not harmful as such but leads to duplicate routes which decreases performance
          app.routes_reloader.paths.uniq!
        end

        initializer "#{engine_name}.register_test_paths" do |app|
          app.config.plugins_to_test_paths << root
        end

        # adds our factories to factory girl's load path
        initializer "#{engine_name}.register_factories", after: 'factory_girl.set_factory_paths' do |_app|
          FactoryGirl.definition_file_paths << File.expand_path(root.to_s + '/spec/factories') if defined?(FactoryGirl)
        end

        initializer "#{engine_name}.append_migrations" do |app|
          unless app.root.to_s.match root.to_s
            config.paths['db/migrate'].expanded.each do |expanded_path|
              app.config.paths['db/migrate'] << expanded_path
            end
          end
        end
      end
    end
  end
end
