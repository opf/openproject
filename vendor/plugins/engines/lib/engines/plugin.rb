# An instance of Plugin is created for each plugin loaded by Rails, and
# stored in the <tt>Engines.plugins</tt> PluginList 
# (see Engines::RailsExtensions::RailsInitializer for more details).
#
#   Engines.plugins[:plugin_name]
#
# Other properties of the Plugin instance can also be set.
module Engines
  class Plugin < Rails::Plugin    
    # Plugins can add paths to this attribute in init.rb if they need
    # controllers loaded from additional locations. 
    attr_accessor :controller_paths
  
    # The directory in this plugin to mirror into the shared directory
    # under +public+.
    #
    # Defaults to "assets" (see default_public_directory).
    attr_accessor :public_directory   
    
    protected
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
      @controller_paths = default_controller_paths
      @public_directory = default_public_directory
    end
  
    # Extends the superclass' load method to additionally mirror public assets
    def load(initializer)
      return if loaded?
      super initializer
      add_plugin_locale_paths
      Assets.mirror_files_for(self)
    end    
  
    # select those paths that actually exist in the plugin's directory
    def select_existing_paths(name)
      Engines.select_existing_paths(self.send(name).map { |p| File.join(directory, p) })
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

