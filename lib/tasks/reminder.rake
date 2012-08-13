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

class DueIssuesReminder
  def initialize(days = nil, project_id = nil, tracker_id = nil, user_ids = [])
    @days     = days ? days.to_i : 7
    @project  = Project.find_by_id(project_id)
    @tracker  = Tracker.find_by_id(tracker_id)
    @user_ids = user_ids
  end

  def remind_users
    s = ARCondition.new ["#{IssueStatus.table_name}.is_closed = ? AND #{Issue.table_name}.due_date <= ?", false, @days.days.from_now.to_date]
    s << "#{Issue.table_name}.assigned_to_id IS NOT NULL"
    s << ["#{Issue.table_name}.assigned_to_id IN (?)", @user_ids] if @user_ids.any?
    s << "#{Project.table_name}.status = #{Project::STATUS_ACTIVE}"
    s << "#{Issue.table_name}.project_id = #{@project.id}" if @project
    s << "#{Issue.table_name}.tracker_id = #{@tracker.id}" if @tracker

    issues_by_assignee = Issue.find(:all, :include => [:status, :assigned_to, :project, :tracker],
                                          :conditions => s.conditions
                                   ).group_by(&:assigned_to)
    issues_by_assignee.each do |assignee, issues|
      UserMailer.reminder_mail(assignee, issues, @days).deliver if assignee && assignee.active?
    end
  end
end

desc <<-END_DESC
Send reminders about issues due in the next days.

Available options:
  * days     => number of days to remind about (defaults to 7)
  * tracker  => id of tracker (defaults to all trackers)
  * project  => id or identifier of project (defaults to all projects)
  * users    => comma separated list of user ids who should be reminded

Example:
  rake redmine:send_reminders days=7 users="1,23, 56" RAILS_ENV="production"
END_DESC

namespace :redmine do
  task :send_reminders => :environment do
    reminder = DueIssuesReminder.new(ENV['days'], ENV['project'], ENV['tracker'], ENV['users'].to_s.split(',').map(&:to_i))
    reminder.remind_users
  end
end
