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

class IssueObserver < ActiveRecord::Observer
  attr_accessor :send_notification

  def after_create(issue)
    if self.send_notification
      (issue.recipients + issue.watcher_recipients).uniq.each do |recipient|
        Mailer.deliver_issue_add(issue, recipient)
      end
    end
    clear_notification
  end

  # Wrap send_notification so it defaults to true, when it's nil
  def send_notification
    return true if @send_notification.nil?
    return @send_notification
  end

  private

  # Need to clear the notification setting after each usage otherwise it might be cached
  def clear_notification
    @send_notification = true
  end
end
