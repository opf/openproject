class PluginManager
  GEMFILE_PLUGINS_PATH = 'Gemfile.plugins'

  def initialize(environment)
    @environment = environment
    @gemfile_plugins = _gemfile_plugins || ''
  end

  def _gemfile_plugins
    if File.exists?(GEMFILE_PLUGINS_PATH)
      File.read(GEMFILE_PLUGINS_PATH)
    end
  end

  def add(name)
    plugin = Plugin.new(name)
    if plugin.included_in?(@gemfile_plugins)
      puts 'Plugin already installed, abort'
      exit
    end
    _write_plugin_to_gemfile_plugins_file(plugin)
    _bundle
    _migrate

    if @environment == 'production'
      _assets_precompile
    else
      _assets_webpack
    end
  end

  def remove(name)
    plugin = Plugin.new(name)
    unless plugin.included_in?(@gemfile_plugins)
      puts 'Plugin not installed, abort!'
      exit
    end
    _revert_migrations(plugin)
    _remove_plugin_from_gemfile_plugins_file(plugin)
    _bundle
    if @environment == 'production'
      _assets_clobber
      _assets_precompile
    end
  end

  def _write_plugin_to_gemfile_plugins_file(plugin)
    _add_plugin_to_gemfile_plugins(plugin)
    _sort_gemfile_plugins
    _delete_empty_lines_from_gemfile_plugins
    _remove_duplicated_lines_from_gemfile_plugins
    _check_for_duplicated_plugins
    _write_to_gemfile_plugins_file
  end

  def _add_plugin_to_gemfile_plugins(plugin)
    @gemfile_plugins << plugin.gemfile_plugins_line
    @gemfile_plugins << plugin.gemfile_plugins_lines_for_dependencies
  end

  def _sort_gemfile_plugins
    # Unfortunately, the order of the calls is important.
    # Reporting engine needs to be above openproject-reporting/costs
    _move_plugin_on_top('reporting_engine')
    # Global Roles needs to be on top because it changes the permission model.
    _move_plugin_on_top('openproject-global_roles')
  end

  def _move_plugin_on_top(plugin_name)
    @gemfile_plugins = @gemfile_plugins.split("\n").inject('') do |result, line|
      line.include?(plugin_name) ? line + "\n" + result : result + "\n" + line
    end
  end

  def _delete_empty_lines_from_gemfile_plugins
    @gemfile_plugins.gsub!(/^$\n/, '')
  end

  def _remove_duplicated_lines_from_gemfile_plugins
    gemfile_plugins_lines = @gemfile_plugins.split("\n")
    @gemfile_plugins = gemfile_plugins_lines.uniq.join("\n")
  end

  def _check_for_duplicated_plugins
    Plugin.available_plugins.each do |plugin_name, _|
      occurences = @gemfile_plugins.scan(/#{plugin_name}.*/).count
      if occurences > 1
        puts "#{plugin_name} occurs more than once in your Gemfile.plugins, abort!"
        exit
      end
    end
  end

  def _write_to_gemfile_plugins_file
    File.open(GEMFILE_PLUGINS_PATH, 'w') do |f|
      f.write @gemfile_plugins
    end
  end

  def _bundle
    Bundler.with_clean_env do
      system 'bundle install --no-deployment'
    end
  end

  def _migrate
    system "RAILS_ENV='#{@environment}' bundle exec rake db:migrate"
  end

  def _revert_migrations(plugin)
    migration_path = OpenProject::Application.config.paths['db/migrate'].select { |path| path.include?(plugin.name) }
    ActiveRecord::Migrator.migrate migration_path, 0
  end

  def _assets_precompile
    system "RAILS_ENV='production' bundle exec rake assets:precompile"
  end

  def _assets_webpack
    system "RAILS_ENV='production' bundle exec rake assets:webpack"
  end

  def _assets_clobber
    system "RAILS_ENV='production' bundle exec rake assets:clobber"
  end

  def _remove_plugin_from_gemfile_plugins_file(plugin)
    _remove_plugin_from_gemfile_plugins(plugin)
    _write_to_gemfile_plugins_file
    _remove_gemfile_plugins_if_empty
  end

  def _remove_plugin_from_gemfile_plugins(plugin)
    gemfile_plugins_new = ''
    plugins = [plugin].concat _dependencies_only_required_by(plugin)
    @gemfile_plugins.each_line do |line|
      gemfile_plugins_new << line if _line_contains_no_plugin?(line, plugins)
    end
    @gemfile_plugins = gemfile_plugins_new
  end

  def _dependencies_only_required_by(plugin)
    dependencies = plugin.dependencies
    dependencies.select { |dependency| dependency._not_needed_by_any_other_than?(plugin) }
  end

  def _line_contains_no_plugin?(line, plugins)
    result = true
    plugins.each do |plugin|
      result = false if plugin.included_in?(line)
    end
    result
  end

  def _remove_gemfile_plugins_if_empty
    FileUtils.rm(GEMFILE_PLUGINS_PATH) if @gemfile_plugins == ''
  end
end

class Plugin
  PLUGINS_YML_PATH = 'plugins.yml'

  def self._available?(name)
    available_plugins[name]
  end

  def self.available_plugins
    @available_plugins ||= _load_available_plugins
  end

  def self._load_available_plugins
    unless File.exists?(PLUGINS_YML_PATH)
      puts 'Could not find plugin list, abort!'
      exit
    end
    YAML.load_file(PLUGINS_YML_PATH)
  end

  attr_reader :name

  def initialize(name)
    unless Plugin._available?(name)
      puts 'Could not find plugin, abort!'
      exit
    end
    @name = name
  end

  def _not_needed_by_any_other_than?(plugin)
    all_other_plugin_names = Plugin.available_plugins.inject([]) do |result, (other_name, _)|
      plugin.name == other_name ? result : result << other_name
    end
    all_other_plugins = all_other_plugin_names.inject([]) do |result, name|
      result << Plugin.new(name)
    end
    all_dependencies_from_other_plugins = all_other_plugins.inject([]) do |result, other_plugin|
      result.concat other_plugin.dependencies
    end
    all_dependencies_from_other_plugins.any? { |dependency| dependency.name == name }
  end

  def included_in?(str)
    str.include?(@name)
  end

  def gemfile_plugins_line
    options = Plugin.available_plugins[@name]
    result = "gem \"#{@name}\", "
    result << _specs_for_gemfile_plugins_line(options)
    result << "\n"
  end

  def _specs_for_gemfile_plugins_line(options)
    # todo what about tags or commits?
    # Right now we only support gems from rubygems and from git
    # If the plugin has a key :url git will be used.
    # Else a version should be available.
    if options[:url]
      url = options[:url]
      if options[:branch]
        branch = options[:branch]
        ref = "branch: \"#{branch}\""
      end
      "git: \"#{url}\", #{ref}"
    else
      options[:version]
    end

  end

  def gemfile_plugins_lines_for_dependencies
    result = ''
    dependencies.each do |dependency|
      result << dependency.gemfile_plugins_line
    end
    result
  end

  def dependencies
    # We might have to solve dependencies of dependencies.
    available_plugins_names = Plugin.available_plugins[name][:dependencies] || []
    available_plugins_names.inject([]) { |plugins, name| plugins << Plugin.new(name) }
  end
end
