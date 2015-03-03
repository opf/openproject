class PluginManager
  def initialize(environment)
    @environment = environment
    @gemfile_plugins = _gemfile_plugins || ''
  end

  def _gemfile_plugins
    gemfile_plugins_path = 'Gemfile.plugins'
    if File.exists?(gemfile_plugins_path)
      File.read(gemfile_plugins_path)
    end
  end

  def add(plugin)
    if _already_installed?(plugin)
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

  def remove(plugin)
    unless _already_installed?(plugin)
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

  def _already_installed?(plugin)
    @gemfile_plugins.include?(plugin)
  end

  def _write_plugin_to_gemfile_plugins_file(plugin)
    _add_plugin_to_gemfile_plugins(plugin)
    _sort_gemfile_plugins
    _write_to_gemfile_plugins_file
  end

  def _add_plugin_to_gemfile_plugins(plugin)
    unless _available_plugins[plugin]
      puts 'Could not find plugin, abort!'
      exit
    end
    @gemfile_plugins << _gemfile_plugins_line(plugin)
    @gemfile_plugins << _gemfile_plugins_lines_for_dependencies(plugin)
  end

  def _available_plugins
    @available_plugins || _load_available_plugins
  end

  def _load_available_plugins
    @available_plugins = YAML.load_file('plugins.yml')
  end

  def _gemfile_plugins_line(plugin)
    # todo this needs to be more general, i.e. without if 'pdf-inspector'
    # and with different ref types (commit, tag)
    if plugin == 'pdf-inspector'
      "gem \"pdf-inspector\", \"~>1.0.0\"\n"
    else
      url = _available_plugins[plugin][:url]
      branch = _available_plugins[plugin][:branch]
      "gem \"#{plugin}\", git: \"#{url}\", branch: \"#{branch}\"\n"
    end
  end

  def _gemfile_plugins_lines_for_dependencies(plugin)
    # todo don't add dependencies twice
    result = ''
    _dependencies(plugin).each do |dependency|
      result << _gemfile_plugins_line(dependency)
    end
    result
  end

  def _dependencies(plugin)
    result = _available_plugins[plugin][:dependencies] || []
    # todo we have to solve dependencies of dependencies
    # this is just a workaround to make backlogs work for now
    result << 'pdf-inspector' if result == ['openproject-pdf_export']
    result
  end

  def _sort_gemfile_plugins
    # todo we have to take of the order..
    # e.g. global roles first and
    # reporting engine before costs/reporting
  end

  def _write_to_gemfile_plugins_file
    gemfile_plugins_path = 'Gemfile.plugins'
    File.open(gemfile_plugins_path, 'w') do |f|
      f.write @gemfile_plugins
    end
  end

  def _bundle
    Bundler.with_clean_env do
      system 'bundle install --no-deployment'
    end
  end

  def _migrate
    # todo should we migrate for all envs?
    system "RAILS_ENV='#{@environment}' rake db:migrate"
  end

  def _revert_migrations(plugin)
    # todo should we migrate for all envs?
    migration_path = OpenProject::Application.config.paths['db/migrate'].select { |path| path.include?(plugin) }
    ActiveRecord::Migrator.migrate migration_path, 0
  end

  def _assets_precompile
    system "RAILS_ENV='production' rake assets:precompile"
  end

  def _assets_webpack
    system "RAILS_ENV='production' rake assets:webpack"
  end

  def _assets_clobber
    system "RAILS_ENV='production' rake assets:clobber"
  end

  def _remove_plugin_from_gemfile_plugins_file(plugin)
    _remove_plugin_from_gemfile_plugins(plugin)
    _write_to_gemfile_plugins_file
    _remove_gemfile_plugins_if_empty
  end

  def _remove_plugin_from_gemfile_plugins(plugin)
    gemfile_plugins_new = ''
    plugins = [plugin].concat _dependencies_only_for(plugin)
    @gemfile_plugins.each_line do |line|
      gemfile_plugins_new << line if _line_contains_no_plugin?(line, plugins)
    end
    @gemfile_plugins = gemfile_plugins_new
  end

  def _dependencies_only_for(plugin)
    # todo this needs to be addressed
    dependencies = _dependencies(plugin)
    dependencies.select { |dependency| true }#todo dependency._not_needed_by_any_other_than?(plugin) }
  end

  def _not_needed_by_any_other_than?(plugin)
    # todo
    true
  end

  def _line_contains_no_plugin?(line, plugins)
    result = true
    plugins.each do |plugin|
      result = false if line.include?(plugin)
    end
    result
  end

  def _remove_gemfile_plugins_if_empty
    _remove_gemfile_plugins_file if @gemfile_plugins == ''
  end

  def _remove_gemfile_plugins_file
    gemfile_plugins_path = 'Gemfile.plugins'
    FileUtils.rm(gemfile_plugins_path)
  end
end
