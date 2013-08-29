module OpenProject::Documents
  class Engine < ::Rails::Engine
    engine_name :openproject_documents

    config.autoload_paths += Dir["#{config.root}/lib/"]

    spec = Bundler.environment.specs['openproject-documents'][0]

    initializer 'documents.register_plugin' do
      Redmine::Plugin.register :openproject_documents do

        name 'OpenProject Documents'
        author ((spec.authors.kind_of? Array) ? spec.authors[0] : spec.authors)
        author_url "http://www.finn.de"
        description spec.description
        version spec.version
        url spec.homepage

        requires_openproject ">= 3.0.0pre13"

        menu :project_menu, :documents, { :controller => '/documents', :action => 'index' }, :param => :project_id, :caption => :label_document_plural

        permission :manage_documents, {:documents => [:new, :create, :edit, :update, :destroy, :add_attachment]}, :require => :loggedin
        permission :view_documents, :documents => [:index, :show, :download]

        Redmine::Notifiable.all << Redmine::Notifiable.new('document_added')

      end

      Redmine::Search.register :documents
    end


    initializer 'documents.register_observers' do |app|
      # Observers
      ActiveRecord::Base.observers.push :document_observer
    end

    initializer 'documents.precompile_assets' do
      Rails.application.config.assets.precompile += %w(documents.css)
    end

    initializer "documents.register_hooks" do
      require 'open_project/documents/hooks'
    end

    config.before_configuration do |app|
      # This is required for the routes to be loaded first
      # as the routes should be prepended so they take precedence over the core.
      app.config.paths['config/routes'].unshift File.join(File.dirname(__FILE__), "..", "..", "..", "config", "routes.rb")
    end

    initializer "remove_duplicate_documents_routes", :after => "add_routing_paths" do |app|
      # removes duplicate entry from app.routes_reloader
      # As we prepend the plugin's routes to the load_path up front and rails
      # adds all engines' config/routes.rb later, we have double loaded the routes
      # This is not harmful as such but leads to duplicate routes which decreases performance
      app.routes_reloader.paths.uniq!
    end

    # adds our factories to factory girl's load path
    initializer "documents.register_factories", :after => "factory_girl.set_factory_paths" do |app|
      FactoryGirl.definition_file_paths << File.expand_path(self.root.to_s + '/spec/factories') if defined?(FactoryGirl)
    end

    config.to_prepare do
      require_dependency 'open_project/documents/patches/project_patch'
      require_dependency 'open_project/documents/patches/application_helper_patch'
      require_dependency 'open_project/documents/patches/custom_fields_helper_patch'
      require_dependency 'document_category'
      require_dependency 'document_category_custom_field'
    end
  end
end
