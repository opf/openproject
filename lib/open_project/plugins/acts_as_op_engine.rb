module OpenProject::Plugins
  module ActsAsOpEngine

    def self.included(base)
      base.send(:define_method, :name) do
        ActiveSupport::Inflector.demodulize(base).downcase
      end

      base.send(:define_method, :patch) do |target, patch|
        OpenProject::Plugins::PatchRegistry.register(target, patch)
      end

      base.send(:define_method, :load_dependent) do |target, *dependencies|
        OpenProject::Plugins::LoadDependency.register(target, *dependencies)
      end

      base.send(:define_method, :assets) do |assets|
        base.initializer '#{name}.precompile_assets' do |app|
          app.config.assets.precompile += assets.to_a
        end
      end

      base.class_eval do
        config.autoload_paths += Dir["#{config.root}/lib/"]

        config.before_configuration do |app|
          # This is required for the routes to be loaded first
          # as the routes should be prepended so they take precedence over the core.
          app.config.paths['config/routes'].unshift File.join(File.dirname(__FILE__), "..", "..", "..", "config", "routes.rb")
        end

        initializer "#{name}.remove_duplicate_routes", :after => "add_routing_paths" do |app|
          # removes duplicate entry from app.routes_reloader
          # As we prepend the plugin's routes to the load_path up front and rails
          # adds all engines' config/routes.rb later, we have double loaded the routes
          # This is not harmful as such but leads to duplicate routes which decreases performance
          app.routes_reloader.paths.uniq!
        end

        initializer "#{name}.register_test_paths" do |app|
          app.config.plugins_to_test_paths << self.root
        end

        # adds our factories to factory girl's load path
        initializer "#{name}.register_factories", :after => "factory_girl.set_factory_paths" do |app|
          FactoryGirl.definition_file_paths << File.expand_path(self.root.to_s + '/spec/factories') if defined?(FactoryGirl)
        end
      end
    end

  end
end
