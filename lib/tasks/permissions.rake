#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

namespace :redmine do
  desc "List all permissions and the actions registered with them"
  task :permissions => :environment do
    puts "Permission Name - controller/action pairs"
    Redmine::AccessControl.permissions.sort {|a,b| a.name.to_s <=> b.name.to_s }.each do |permission|
      puts ":#{permission.name} - #{permission.actions.join(', ')}"
    end
  end
end
