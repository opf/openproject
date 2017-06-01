# Loads two files automatically from plugins:
#
# 1. `spec/disable_specs.rbs` to disable specs which don't work in conjunction with the
# respective plugin.
# 2. The config spec helper in `spec/config_spec_helper` makes sure that the core specs
# (and other plugins' specs) keep working with this plugin in an OpenProject configuration
# even if it changes things which would otherwise break existing specs.
Rails.application.config.plugins_to_test_paths.each do |dir|
  ['disabled_specs.rb', 'disable_specs.rb', 'config_spec_helper.rb'].each do |file_name|
    file = File.join(dir, 'spec', file_name)

    if File.exists?(file)
      puts "Loading #{file}"
      require file
    end
  end
end
