#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

desc 'Removes watchers from what they can no longer view.'

namespace :redmine do
  namespace :watchers do
    task :prune => :environment do
      Watcher.prune
    end
  end
end
