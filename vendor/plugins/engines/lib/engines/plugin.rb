# An instance of Plugin is created for each plugin loaded by Rails, and
# stored in the <tt>Engines.plugins</tt> PluginList 
# (see Engines::RailsExtensions::RailsInitializer for more details).
#
#   Engines.plugins[:plugin_name]
#
# If this plugin contains paths in directories other than <tt>app/controllers</tt>,
# <tt>app/helpers</tt>, <tt>app/models</tt> and <tt>components</tt>, authors can
# declare this by adding extra paths to #code_paths:
#
#    Rails.plugin[:my_plugin].code_paths << "app/sweepers" << "vendor/my_lib"
#
# Other properties of the Plugin instance can also be set.
module Engines
  class Plugin < Rails::Plugin    
    # Plugins can add code paths to this attribute in init.rb if they 
    # need plugin directories to be added to the load path, i.e.
    #
    #   plugin.code_paths << 'app/other_classes'
    #
    # Defaults to ["app/controllers", "app/helpers", "app/models", "components"]
    attr_accessor :code_paths

    # Plugins can add paths to this attribute in init.rb if they need
    # controllers loaded from additional locations. 
    attr_accessor :controller_paths
  
    # The directory in this plugin to mirror into the shared directory
    # under +public+.
    #
    # Defaults to "assets" (see default_public_directory).
    attr_accessor :public_directory   
    
    protected
  
      # The default set of code paths which will be added to $LOAD_PATH
      # and Dependencies.load_paths
      def default_code_paths
        # lib will actually be removed from the load paths when we call
        # uniq! in #inject_into_load_paths, but it's important to keep it
        # around (for the documentation tasks, for instance).
        %w(app/controllers app/helpers app/models components lib)
      end
    
      # The default set of code paths which will be added to the routing system
      def default_controller_paths
        %w(app/controllers components)
      end

      # Attempts to detect the directory to use for public files.
      # If +assets+ exists in the plugin, this will be used. If +assets+ is missing
      # but +public+ is found, +public+ will be used.
      def default_public_directory
        Engines.select_existing_paths(%w(assets public).map { |p| File.join(directory, p) }).first
      end
    
    public
  
    def initialize(directory)
      super directory
      @code_paths = default_code_paths
      @controller_paths = default_controller_paths
      @public_directory = default_public_directory
    end
  
    # Returns a list of paths this plugin wishes to make available in $LOAD_PATH
    #
    # Overwrites the correspondend method in the superclass  
    def load_paths
      report_nonexistant_or_empty_plugin! unless valid?
      select_existing_paths :code_paths
    end
    
    # Extends the superclass' load method to additionally mirror public assets
    def load(initializer)
      return if loaded?
      super initializer
      add_plugin_view_paths
      add_plugin_locale_paths
      Assets.mirror_files_for(self)
    end    
  
    # for code_paths and controller_paths select those paths that actually 
    # exist in the plugin's directory
    def select_existing_paths(name)
      Engines.select_existing_paths(self.send(name).map { |p| File.join(directory, p) })
    end    

    def add_plugin_view_paths
      view_path = File.join(directory, 'app', 'views')
      if File.exist?(view_path)
        ActionController::Base.view_paths.insert(1, view_path) # push it just underneath the app
      end
    end

    def add_plugin_locale_paths
      locale_path = File.join(directory, 'locales')
      return unless File.exists?(locale_path)

      locale_files = Dir[File.join(locale_path, '*.{rb,yml}')]
      return if locale_files.blank?

      first_app_element = 
        I18n.load_path.select{ |e| e =~ /^#{ RAILS_ROOT }/ }.reject{ |e| e =~ /^#{ RAILS_ROOT }\/vendor\/plugins/ }.first
      app_index = I18n.load_path.index(first_app_element) || - 1

      I18n.load_path.insert(app_index, *locale_files)
    end

    # The path to this plugin's public files
    def public_asset_directory
      "#{File.basename(Engines.public_directory)}/#{name}"
    end
    
    # The path to this plugin's routes file
    def routes_path
      File.join(directory, "routes.rb")
    end

    # The directory containing this plugin's migrations (<tt>plugin/db/migrate</tt>)
    def migration_directory
      File.join(self.directory, 'db', 'migrate')
    end
  
    # Returns the version number of the latest migration for this plugin. Returns
    # nil if this plugin has no migrations.
    def latest_migration
      migrations.last
    end
    
    # Returns the version numbers of all migrations for this plugin.
    def migrations
      migrations = Dir[migration_directory+"/*.rb"]
      migrations.map { |p| File.basename(p).match(/0*(\d+)\_/)[1].to_i }.sort
    end
    
    # Migrate this plugin to the given version. See Engines::Plugin::Migrator for more
    # information.   
    def migrate(version = nil)
      Engines::Plugin::Migrator.migrate_plugin(self, version)
    end
  end
end

