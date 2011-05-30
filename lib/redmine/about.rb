#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

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
