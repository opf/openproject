module Redmine
  class About
    def self.print_plugin_info
      plugins = Redmine::Plugin.registered_plugins

      if !plugins.empty?
        column_with = plugins.map {|internal_name, plugin| plugin.name.length}.max
        puts "\nAbout your Redmine plugins"

        plugins.each do |internal_name, plugin|
          puts sprintf("%-#{column_with}s   %s", plugin.name, plugin.version)
        end
      end
    end
  end
end
