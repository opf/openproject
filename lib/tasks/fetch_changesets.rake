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


desc 'Fetch changesets from the repositories'

namespace :redmine do
  task :fetch_changesets => :environment do
    Repository.fetch_changesets
  end
end
