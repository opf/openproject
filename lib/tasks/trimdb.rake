#-- encoding: UTF-8
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
  desc "Deletes obsolete legacy tables in case they haven't been deleted before."
  task :trim => :environment do
    obsolete_tables = [
      :deliverable_costs, :deliverable_hours, :deliverables, # should've been dropped in RefactorTerms
      :schedule_closed_entries, :schedule_defaults, :schedule_entries # tables of dropped plugin redmine_schedules
    ]

    obsolete_tables.select do |table|
      if ActiveRecord::Base.connection.table_exists? table.to_s
        ActiveRecord::Migration.drop_table table
      end
    end
  end
end
