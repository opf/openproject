#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require Rails.root.join("config/constants/open_project/activity")

module Redmine # :nodoc:
  class PluginError < StandardError
    attr_reader :plugin_id

    def initialize(plug_id = nil)
      super
      @plugin_id = plug_id
    end
  end

  class PluginNotFound < PluginError
    def to_s
      "Missing the plugin #{@plugin_id}"
    end
  end

  class PluginCircularDependency < PluginError
    def to_s
      "Circular plugin dependency in #{@plugin_id}"
    end
  end

  class PluginRequirementError < PluginError; end

  # Base class for Redmine plugins.
  # Plugins are registered using the <tt>register</tt> class method that acts as the public constructor.
  #
  #   Redmine::Plugin.register :example do
  #     name 'Example plugin'
  #     author 'John Smith'
  #     description 'This is an example plugin for Redmine'
  #     version '0.0.1'
  #     settings default: {'foo'=>'bar'}, partial: 'settings/settings'
  #   end
  #
  # === Plugin attributes
  #
  # +settings+ is an optional attribute that let the plugin be configurable.
  # It must be a hash with the following keys:
  # * <tt>:default</tt>: default value for the plugin settings
  # * <tt>:partial</tt>: path of the configuration partial view, relative to the plugin <tt>app/views</tt> directory
  # Example:
  #   settings default: {'foo'=>'bar'}, partial: 'settings/settings'
  # In this example, the settings partial will be found here in the plugin directory: <tt>app/views/settings/_settings.rhtml</tt>.
  #
  # When rendered, the plugin settings value is available as the local variable +settings+
  class Plugin
    @registered_plugins = ActiveSupport::OrderedHash.new
    @deferred_plugins   = {}

    cattr_accessor :public_directory
    self.public_directory = Rails.public_path.join("plugin_assets")

    class << self
      attr_reader :registered_plugins, :deferred_plugins
      private :new

      def def_field(*names)
        class_eval do
          names.each do |name|
            define_method(name) do |*args|
              args.empty? ? instance_variable_get(:"@#{name}") : instance_variable_set(:"@#{name}", *args)
            end
          end
        end
      end
    end
    def_field :gem_name, :url, :author, :author_url, :version, :settings, :bundled
    alias :bundled? :bundled
    attr_reader :id

    # Plugin constructor
    def self.register(id, &block)
      id = id.to_sym
      p = new(id)
      p.instance_eval(&block)

      registered_plugins[id] = p

      if p.settings
        Settings::Definition.add("plugin_#{id}",
                                 default: p.settings[:default],
                                 format: :hash,
                                 env_alias: p.settings[:env_alias])
      end

      # If there are plugins waiting for us to be loaded, we try loading those, again
      if deferred_plugins[id]
        deferred_plugins[id].each do |ary|
          plugin_id, block = ary
          register(plugin_id, &block)
        end
        deferred_plugins.delete(id)
      end

      p
    rescue PluginNotFound => e
      # find circular dependencies
      raise PluginCircularDependency.new(id) if dependencies_for(e.plugin_id).include?(id)

      raise
    end

    def name(*args)
      name = args.empty? ? instance_variable_get(:@name) : instance_variable_set(:@name, *args)

      return ::I18n.t(name) if name.is_a?(Symbol)
      return name if name

      translated_name = ::I18n.t("plugin_#{id}.name", default: nil)
      translated_name || gemspec&.summary || id.to_s.humanize
    end

    def description(*args)
      description = args.empty? ? instance_variable_get(:@description) : instance_variable_set(:@description, *args)

      description || ::I18n.t("plugin_#{id}.description", default: gemspec&.description)
    end

    def gemspec
      Gem.loaded_specs[gem_name]
    end

    # returns an array of all dependencies we know of for plugin id
    # (might not be complete at all times!)
    def self.dependencies_for(id)
      direct_deps = deferred_plugins.keys.find_all { |k| deferred_plugins[k].map(&:first).include?(id) }
      direct_deps.inject([]) do |deps, v|
        deps << v
        deps += dependencies_for(v)
      end
    end

    # Returns an array of all registered plugins
    def self.all
      registered_plugins.values
    end

    def self.not_bundled
      registered_plugins
        .values
        .reject(&:bundled)
    end

    # Finds a plugin by its id
    # Returns a PluginNotFound exception if the plugin doesn't exist
    def self.find(id)
      registered_plugins[id.to_sym] || raise(PluginNotFound.new(id.to_sym))
    end

    # Clears the registered plugins hash
    # It doesn't unload installed plugins
    def self.clear
      @registered_plugins = {}
    end

    # Checks if a plugin is installed
    #
    # @param [String] id name of the plugin
    def self.installed?(id)
      registered_plugins[id.to_sym].present?
    end

    def initialize(id)
      @id = id.to_sym
    end

    def <=>(other)
      id.to_s <=> other.id.to_s
    end

    # Sets a requirement on the OpenProject version.
    # Raises a PluginRequirementError exception if the requirement is not met.
    #
    # It uses the same syntax as rubygems requirements.
    # Examples
    #   # Requires exactly OpenProject 1.1.1
    #   requires_openproject "1.1.1"
    #   requires_openproject "= 1.1.1"

    #   # Requires OpenProject 1.1.x
    #   requires_openproject "~> 1.1.0"

    #   # Requires OpenProject between 1.1.0 and 1.1.5 or higher
    #   requires_openproject ">= 1.1.0", "<= 1.1.5"

    def requires_openproject(*)
      required_version = Gem::Requirement.new(*)
      op_version = Gem::Version.new(OpenProject::VERSION.to_semver)

      unless required_version.satisfied_by? op_version
        raise PluginRequirementError.new("#{id} plugin requires OpenProject version #{required_version} but current version is #{op_version}.")
      end

      true
    end

    # Raises a PluginRequirementError exception if the requirement is not met
    #
    # Examples
    #   # Requires a plugin named :foo version 0.7.3 or higher
    #   requires_redmine_plugin :foo, version_or_higher: '0.7.3'
    #   requires_redmine_plugin :foo, '0.7.3'
    #
    #   # Requires a specific version of a Redmine plugin
    #   requires_redmine_plugin :foo, version: '0.7.3'              # 0.7.3 only
    #   requires_redmine_plugin :foo, version: ['0.7.3', '0.8.0']   # 0.7.3 or 0.8.0
    def requires_redmine_plugin(plugin_name, arg)
      arg = { version_or_higher: arg } unless arg.is_a?(Hash)
      arg.assert_valid_keys(:version, :version_or_higher)

      plugin = Plugin.find(plugin_name)
      current = plugin.version.split(".").map(&:to_i)

      arg.each do |k, v|
        v = [] << v unless v.is_a?(Array)
        versions = v.map { |s| s.split(".").map(&:to_i) }
        case k
        when :version_or_higher
          raise ArgumentError.new("wrong number of versions (#{versions.size} for 1)") unless versions.size == 1
          unless (current <=> versions.first) >= 0
            raise PluginRequirementError.new("#{id} plugin requires the #{plugin_name} plugin #{v} or higher but current is #{current.join('.')}")
          end
        when :version
          unless versions.include?(current.slice(0, 3))
            raise PluginRequirementError.new("#{id} plugin requires one the following versions of #{plugin_name}: #{v.join(', ')} but current is #{current.join('.')}")
          end
        end
      end
      true
    end

    # Adds an item to the given +menu+.
    # The +id+ parameter (equals to the project id) is automatically added to the url.
    #   menu :project_menu, :plugin_example, { controller: '/example', action: 'say_hello' }, caption: 'Sample'
    #
    # +name+ parameter can be: :top_menu, :account_menu, :application_menu or :project_menu
    #
    def menu(menu_name, item, url, options = {})
      Redmine::MenuManager.map(menu_name) do |menu|
        menu.push(item, url, options)
      end
    end
    alias :add_menu_item :menu

    def configure_menu(menu_name, &)
      Redmine::MenuManager.map(menu_name, &)
    end

    # Removes +item+ from the given +menu+.
    def delete_menu_item(menu_name, item)
      hide_menu_item(menu_name, item)
    end

    # Allows to hide an existing +item+ in a menu.
    #
    # +hide_if+ parameter can be a lambda accepting a project, the item will only be hidden if
    #   the condition evaluates to true.
    def hide_menu_item(menu_name, item, hide_if: ->(*) { true })
      Redmine::MenuManager.map(menu_name) do |menu|
        menu.add_condition(item, ->(project) { !hide_if.call(project) })
      end
    end

    def rename_menu_item(menu_name, item, options)
      Redmine::MenuManager.map(menu_name) do |menu|
        menu_item = menu.find(item)
        menu_item.caption = options[:caption]
        menu_item.icon = options[:icon]
        menu_item.badge = options[:badge]
        menu_item.url = options[:url]
      end
    end

    # Defines a permission called +name+ for the given +actions+.
    #
    # The +actions+ argument is a hash with controllers as keys and actions as values (a single value or an array):
    #   permission :destroy_contacts, { contacts: :destroy }
    #   permission :view_contacts, { contacts: [:index, :show] }
    #
    # The +options+ argument can be used to make the permission public (implicitly given to any user)
    # or to restrict users the permission can be given to.
    #
    # Examples
    #   # A permission that is implicitly given to any user
    #   # This permission won't appear on the Roles & Permissions setup screen
    #   permission :say_hello, { example: :say_hello }, public: true
    #
    #   # A permission that can be given to any user
    #   permission :say_hello, { example: :say_hello }
    #
    #   # A permission that can be given to registered users only
    #   permission :say_hello, { example: :say_hello }, require: :loggedin
    #
    #   # A permission that can be given to project members only
    #   permission :say_hello, { example: :say_hello }, require: :member
    def permission(name, actions, options = {})
      if @project_scope
        mod, mod_options = @project_scope
        OpenProject::AccessControl.map do |map|
          map.project_module(mod, mod_options) do |map|
            map.permission(name, actions, **options)
          end
        end
      else
        OpenProject::AccessControl.map { |map| map.permission(name, actions, **options) }
      end
    end

    # Defines a project module, that can be enabled/disabled for each project.
    # Permissions defined inside +block+ will be bind to the module.
    #
    #   project_module :things do
    #     permission :view_contacts, { contacts: [:list, :show] }, public: true
    #     permission :destroy_contacts, { contacts: :destroy }
    #   end
    def project_module(name, options = {}, &)
      plugin = self
      Rails.application.reloader.to_prepare do
        plugin.instance_eval { @project_scope = [name, options] }
        plugin.instance_eval(&)
      end
    ensure
      plugin.instance_eval { @project_scope = nil }
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
    #   register :scrums, class_name: 'Meeting'
    #   register :issues, class_name: ['Issue', 'Journal']
    #
    # Retrieving events:
    # Associated model(s) must implement the find_events class method.
    #
    # The following call should return all the scrum events visible by current user that occurred in the 5 last days:
    #   Meeting.find_events('scrums', User.current, 5.days.ago, Date.today)
    #   Meeting.find_events('scrums', User.current, 5.days.ago, Date.today, project: foo) # events for project foo only
    #
    # Note that :view_scrums permission is required to view these events in the activity view.
    def activity_provider(*)
      ActiveSupport::Deprecation.warn("Use ActsAsOpEngine#activity_provider instead.")
      OpenProject::Activity.register(*)
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
      settings.is_a?(Hash) && settings[:partial].present?
    end

    def mirror_assets
      source = assets_directory
      destination = public_directory
      return unless File.directory?(source)

      source_files = Dir["#{source}/**/*"]
      source_dirs = source_files.select { |d| File.directory?(d) }
      source_files -= source_dirs

      unless source_files.empty?
        base_target_dir = File.join(destination, File.dirname(source_files.first).gsub(source, ""))
        FileUtils.mkdir_p(base_target_dir)
      end

      source_dirs.each do |dir|
        # strip down these paths so we have simple, relative paths we can
        # add to the destination
        target_dir = File.join(destination, dir.gsub(source, ""))
        begin
          FileUtils.mkdir_p(target_dir)
        rescue StandardError => e
          raise "Could not create directory #{target_dir}: \n" + e
        end
      end

      source_files.each do |file|
        target = File.join(destination, file.gsub(source, ""))
        unless File.exist?(target) && FileUtils.identical?(file, target)
          FileUtils.cp(file, target)
        end
      rescue StandardError => e
        raise "Could not copy #{file} to #{target}: \n" + e
      end
    end

    # Mirrors assets from one or all plugins to public/plugin_assets
    def self.mirror_assets(name = nil)
      if name.present?
        find(name).mirror_assets
      else
        all.each(&:mirror_assets)
      end
    end
  end
end
