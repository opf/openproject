def to_gem_name(plugin_name)
  plugin_name.to_s.sub('openproject_', 'openproject-')
end

plugin_name_paths = Redmine::Plugin.all.inject({}) do |result, plugin|
  gem_name = to_gem_name(plugin.id)
  gem_path = Gem.loaded_specs[gem_name].full_gem_path
  result[gem_name] = gem_path
  result
end

puts JSON.generate(plugin_name_paths)
