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

namespace :db do
  desc 'Migrates installed plugins.'
  task :migrate_plugins => :environment do
    if Rails.respond_to?('plugins')
      Rails.plugins.each do |plugin|
        next unless plugin.respond_to?('migrate')
        puts "Migrating #{plugin.name}..."
        plugin.migrate
      end
    else
      puts "Undefined method plugins for Rails!"
      puts "Make sure engines plugin is installed."
    end
  end
end
