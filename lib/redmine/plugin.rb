# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

module Redmine #:nodoc:

  class PluginNotFound < StandardError; end
  class PluginRequirementError < StandardError; end
  
  # Base class for Redmine plugins.
  # Plugins are registered using the <tt>register</tt> class method that acts as the public constructor.
  # 
  #   Redmine::Plugin.register :example do
  #     name 'Example plugin'
  #     author 'John Smith'
  #     description 'This is an example plugin for Redmine'
  #     version '0.0.1'
  #     settings :default => {'foo'=>'bar'}, :partial => 'settings/settings'
  #   end
  # 
  # === Plugin attributes
  # 
  # +settings+ is an optional attribute that let the plugin be configurable.
  # It must be a hash with the following keys:
  # * <tt>:default</tt>: default value for the plugin settings
  # * <tt>:partial</tt>: path of the configuration partial view, relative to the plugin <tt>app/views</tt> directory
  # Example:
  #   settings :default => {'foo'=>'bar'}, :partial => 'settings/settings'
  # In this example, the settings partial will be found here in the plugin directory: <tt>app/views/settings/_settings.rhtml</tt>.
  # 
  # When rendered, the plugin settings value is available as the local variable +settings+
  class Plugin
    @registered_plugins = {}
    class << self
      attr_reader :registered_plugins
      private :new

      def def_field(*names)
        class_eval do 
          names.each do |name|
            define_method(name) do |*args| 
              args.empty? ? instance_variable_get("@#{name}") : instance_variable_set("@#{name}", *args)
            end
          end
        end
      end
    end
    def_field :name, :description, :url, :author, :author_url, :version, :settings
    attr_reader :id
    
    # Plugin constructor
    def self.register(id, &block)
      p = new(id)
      p.instance_eval(&block)
      # Set a default name if it was not provided during registration
      p.name(id.to_s.humanize) if p.name.nil?
      # Adds plugin locales if any
      # YAML translation files should be found under <plugin>/config/locales/
      ::I18n.load_path += Dir.glob(File.join(RAILS_ROOT, 'vendor', 'plugins', id.to_s, 'config', 'locales', '*.yml'))
      registered_plugins[id] = p
    end
    
    # Returns an array off all registered plugins
    def self.all
      registered_plugins.values.sort
    end
    
    # Finds a plugin by its id
    # Returns a PluginNotFound exception if the plugin doesn't exist
    def self.find(id)
      registered_plugins[id.to_sym] || raise(PluginNotFound)
    end
    
    # Clears the registered plugins hash
    # It doesn't unload installed plugins
    def self.clear
      @registered_plugins = {}
    end
    
    def initialize(id)
      @id = id.to_sym
    end
    
    def <=>(plugin)
      self.id.to_s <=> plugin.id.to_s
    end
    
    # Sets a requirement on Redmine version
    # Raises a PluginRequirementError exception if the requirement is not met
    #
    # Examples
    #   # Requires Redmine 0.7.3 or higher
    #   requires_redmine :version_or_higher => '0.7.3'
    #   requires_redmine '0.7.3'
    #
    #   # Requires a specific Redmine version
    #   requires_redmine :version => '0.7.3'              # 0.7.3 only
    #   requires_redmine :version => ['0.7.3', '0.8.0']   # 0.7.3 or 0.8.0
    def requires_redmine(arg)
      arg = { :version_or_higher => arg } unless arg.is_a?(Hash)
      arg.assert_valid_keys(:version, :version_or_higher)
      
      current = Redmine::VERSION.to_a
      arg.each do |k, v|
        v = [] << v unless v.is_a?(Array)
        versions = v.collect {|s| s.split('.').collect(&:to_i)}
        case k
        when :version_or_higher
          raise ArgumentError.new("wrong number of versions (#{versions.size} for 1)") unless versions.size == 1
          unless (current <=> versions.first) >= 0
            raise PluginRequirementError.new("#{id} plugin requires Redmine #{v} or higher but current is #{current.join('.')}")
          end
        when :version
          unless versions.include?(current.slice(0,3))
            raise PluginRequirementError.new("#{id} plugin requires one the following Redmine versions: #{v.join(', ')} but current is #{current.join('.')}")
          end
        end
      end
      true
    end

    # Adds an item to the given +menu+.
    # The +id+ parameter (equals to the project id) is automatically added to the url.
    #   menu :project_menu, :plugin_example, { :controller => 'example', :action => 'say_hello' }, :caption => 'Sample'
    #   
    # +name+ parameter can be: :top_menu, :account_menu, :application_menu or :project_menu
    # 
    def menu(menu, item, url, options={})
      Redmine::MenuManager.map(menu).push(item, url, options)
    end
    alias :add_menu_item :menu
    
    # Removes +item+ from the given +menu+.
    def delete_menu_item(menu, item)
      Redmine::MenuManager.map(menu).delete(item)
    end

    # Defines a permission called +name+ for the given +actions+.
    # 
    # The +actions+ argument is a hash with controllers as keys and actions as values (a single value or an array):
    #   permission :destroy_contacts, { :contacts => :destroy }
    #   permission :view_contacts, { :contacts => [:index, :show] }
    # 
    # The +options+ argument can be used to make the permission public (implicitly given to any user)
    # or to restrict users the permission can be given to.
    # 
    # Examples
    #   # A permission that is implicitly given to any user
    #   # This permission won't appear on the Roles & Permissions setup screen
    #   permission :say_hello, { :example => :say_hello }, :public => true
    # 
    #   # A permission that can be given to any user
    #   permission :say_hello, { :example => :say_hello }
    #   
    #   # A permission that can be given to registered users only
    #   permission :say_hello, { :example => :say_hello }, :require => loggedin
    #   
    #   # A permission that can be given to project members only
    #   permission :say_hello, { :example => :say_hello }, :require => member
    def permission(name, actions, options = {})
      if @project_module
        Redmine::AccessControl.map {|map| map.project_module(@project_module) {|map|map.permission(name, actions, options)}}
      else
        Redmine::AccessControl.map {|map| map.permission(name, actions, options)}
      end
    end
    
    # Defines a project module, that can be enabled/disabled for each project.
    # Permissions defined inside +block+ will be bind to the module.
    # 
    #   project_module :things do
    #     permission :view_contacts, { :contacts => [:list, :show] }, :public => true
    #     permission :destroy_contacts, { :contacts => :destroy }
    #   end
    def project_module(name, &block)
      @project_module = name
      self.instance_eval(&block)
      @project_module = nil
    end
    
    # Registers an activity provider.
    #
    # Options:
    # * <tt>:class_name</tt> - one or more model(s) that provide these events (inferred from event_type by default)
    # * <tt>:default</tt> - setting this option to false will make the events not displayed by default
    # 
    # A model can provide several activity event types.
    # 
    # Examples:
    #   register :news
    #   register :scrums, :class_name => 'Meeting'
    #   register :issues, :class_name => ['Issue', 'Journal']
    # 
    # Retrieving events:
    # Associated model(s) must implement the find_events class method.
    # ActiveRecord models can use acts_as_activity_provider as a way to implement this class method.
    # 
    # The following call should return all the scrum events visible by current user that occured in the 5 last days: 
    #   Meeting.find_events('scrums', User.current, 5.days.ago, Date.today)
    #   Meeting.find_events('scrums', User.current, 5.days.ago, Date.today, :project => foo) # events for project foo only
    # 
    # Note that :view_scrums permission is required to view these events in the activity view.
    def activity_provider(*args)
      Redmine::Activity.register(*args)
    end
    
    # Registers a wiki formatter.
    #
    # Parameters:
    # * +name+ - human-readable name
    # * +formatter+ - formatter class, which should have an instance method +to_html+
    # * +helper+ - helper module, which will be included by wiki pages
    def wiki_format_provider(name, formatter, helper)
      Redmine::WikiFormatting.register(name, formatter, helper)
    end

    # Returns +true+ if the plugin can be configured.
    def configurable?
      settings && settings.is_a?(Hash) && !settings[:partial].blank?
    end
  end
end
