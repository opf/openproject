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

desc <<-END_DESC
Send reminders about issues due in the next days.

Available options:
  * days     => number of days to remind about (defaults to 7)
  * type     => id of type (defaults to all type)
  * project  => id or identifier of project (defaults to all projects)
  * users    => comma separated list of user ids who should be reminded

Example:
  rake redmine:send_reminders days=7 users="1,23, 56" RAILS_ENV="production"
END_DESC

namespace :redmine do
  task :send_reminders => :environment do
    reminder = DueIssuesReminder.new(ENV['days'], ENV['project'], ENV['type'], ENV['users'].to_s.split(',').map(&:to_i))
    reminder.remind_users
  end
end
