#-- encoding: UTF-8
require 'active_support'
require File.join(File.dirname(__FILE__), 'engines/plugin')
require File.join(File.dirname(__FILE__), 'engines/plugin/list')
require File.join(File.dirname(__FILE__), 'engines/plugin/loader')
require File.join(File.dirname(__FILE__), 'engines/plugin/locator')
require File.join(File.dirname(__FILE__), 'engines/assets')
require File.join(File.dirname(__FILE__), 'engines/rails_extensions/rails')

# == Parameters
#
# The Engines module has a number of public configuration parameters:
#
# [+public_directory+]  The directory into which plugin assets should be
#                       mirrored. Defaults to <tt>RAILS_ROOT/public/plugin_assets</tt>.
# [+schema_info_table+] The table to use when storing plugin migration 
#                       version information. Defaults to +plugin_schema_info+.
#
# Additionally, there are a few flags which control the behaviour of
# some of the features the engines plugin adds to Rails:
#
# [+disable_application_view_loading+] A boolean flag determining whether
#                                      or not views should be loaded from 
#                                      the main <tt>app/views</tt> directory.
#                                      Defaults to false; probably only 
#                                      useful when testing your plugin.
# [+disable_application_code_loading+] A boolean flag determining whether
#                                      or not to load controllers/helpers 
#                                      from the main +app+ directory,
#                                      if corresponding code exists within 
#                                      a plugin. Defaults to false; again, 
#                                      probably only useful when testing 
#                                      your plugin.
# [+disable_code_mixing+] A boolean flag indicating whether all plugin
#                         copies of a particular controller/helper should 
#                         be loaded and allowed to override each other, 
#                         or if the first matching file should be loaded 
#                         instead. Defaults to false.
#
module Engines
  # The set of all loaded plugins
  mattr_accessor :plugins
  self.plugins = Engines::Plugin::List.new  
  
  # List of extensions to load, can be changed in init.rb before calling Engines.init
  mattr_accessor :rails_extensions
  self.rails_extensions = %w(asset_helpers form_tag_helpers migrations dependencies)
  
  # The name of the public directory to mirror public engine assets into.
  # Defaults to <tt>RAILS_ROOT/public/plugin_assets</tt>.
  mattr_accessor :public_directory
  self.public_directory = File.join(RAILS_ROOT, 'public', 'plugin_assets')

  # The table in which to store plugin schema information. Defaults to
  # "plugin_schema_info".
  mattr_accessor :schema_info_table
  self.schema_info_table = "plugin_schema_info"

  #--
  # These attributes control the behaviour of the engines extensions
  #++
  
  # Set this to true if views should *only* be loaded from plugins
  mattr_accessor :disable_application_view_loading
  self.disable_application_view_loading = false
  
  # Set this to true if controller/helper code shouldn't be loaded 
  # from the application
  mattr_accessor :disable_application_code_loading
  self.disable_application_code_loading = false
  
  # Set this to true if code should not be mixed (i.e. it will be loaded
  # from the first valid path on $LOAD_PATH)
  mattr_accessor :disable_code_mixing
  self.disable_code_mixing = false
  
  # This is used to determine which files are candidates for the "code
  # mixing" feature that the engines plugin provides, where classes from
  # plugins can be loaded, and then code from the application loaded
  # on top of that code to override certain methods.
  mattr_accessor :code_mixing_file_types
  self.code_mixing_file_types = %w(controller helper)
  
  class << self
    def init(initializer)
      load_extensions
      Engines::Assets.initialize_base_public_directory
    end
    
    def logger
      RAILS_DEFAULT_LOGGER
    end
    
    def load_extensions
      rails_extensions.each { |name| require "engines/rails_extensions/#{name}" }
      # load the testing extensions, if we are in the test environment.
      require "engines/testing" if RAILS_ENV == "test"
    end
    
    def select_existing_paths(paths)
      paths.select { |path| File.directory?(path) }
    end  
  
    # The engines plugin will, by default, mix code from controllers and helpers,
    # allowing application code to override specific methods in the corresponding
    # controller or helper classes and modules. However, if other file types should
    # also be mixed like this, they can be added by calling this method. For example,
    # if you want to include "things" within your plugin and override them from
    # your applications, you should use the following layout:
    #
    #   app/
    #    +-- things/
    #    |       +-- one_thing.rb
    #    |       +-- another_thing.rb
    #   ...
    #   vendor/
    #       +-- plugins/
    #                +-- my_plugin/
    #                           +-- app/
    #                                +-- things/
    #                                        +-- one_thing.rb
    #                                        +-- another_thing.rb
    #
    # The important point here is that your "things" are named <whatever>_thing.rb,
    # and that they are placed within plugin/app/things (the pluralized form of 'thing').
    # 
    # It's important to note that you'll also want to ensure that the "things" are
    # on your load path by including them in Rails load path mechanism, e.g. in init.rb:
    #
    #  ActiveSupport::Dependencies.load_paths << File.join(File.dirname(__FILE__), 'app', 'things'))
    #
    def mix_code_from(*types)
      self.code_mixing_file_types += types.map { |x| x.to_s.singularize }
    end
    
    # A general purpose method to mirror a directory (+source+) into a destination
    # directory, including all files and subdirectories. Files will not be mirrored
    # if they are identical already (checked via FileUtils#identical?).
    def mirror_files_from(source, destination)
      return unless File.directory?(source)
      
      # TODO: use Rake::FileList#pathmap?    
      source_files = Dir[source + "/**/*"]
      source_dirs = source_files.select { |d| File.directory?(d) }
      source_files -= source_dirs
      
      unless source_files.empty?
        base_target_dir = File.join(destination, File.dirname(source_files.first).gsub(source, ''))
        FileUtils.mkdir_p(base_target_dir)
      end
      
      source_dirs.each do |dir|
        # strip down these paths so we have simple, relative paths we can
        # add to the destination
        target_dir = File.join(destination, dir.gsub(source, ''))
        begin        
          FileUtils.mkdir_p(target_dir)
        rescue Exception => e
          raise "Could not create directory #{target_dir}: \n" + e
        end
      end
      
      source_files.each do |file|
        begin
          target = File.join(destination, file.gsub(source, ''))
          unless File.exist?(target) && FileUtils.identical?(file, target)
            FileUtils.cp(file, target)
          end 
        rescue Exception => e
          raise "Could not copy #{file} to #{target}: \n" + e 
        end
      end  
    end   
  end  
end
