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

class WorkPackageDataObserver < ActiveRecord::Observer
  attr_accessor :send_notification

  def after_create(issue)
    if self.send_notification
      recipients = issue.recipients + issue.watcher_recipients
      users = User.find_all_by_mails(recipients.uniq)
      users.each do |user|
        UserMailer.issue_added(user, issue).deliver
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
