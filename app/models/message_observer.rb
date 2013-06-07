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

class MessageObserver < ActiveRecord::Observer
  def after_create(message)
    if Setting.notified_events.include?('message_posted')
      recipients = message.recipients
      recipients += message.root.watcher_recipients
      recipients += message.board.watcher_recipients
      users = User.find_all_by_mails(recipients.uniq)
      users.each do |user|
        UserMailer.message_posted(user, message).deliver
      end
    end
  end
end
