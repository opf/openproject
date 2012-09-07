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

class CommentObserver < ActiveRecord::Observer
  def after_create(comment)
    return unless Notifier.notify?(:news_comment_added)

    if comment.commented.is_a?(News)
      news = comment.commented
      recipients = news.recipients + news.watcher_recipients
      users = User.find_all_by_mails(recipients)
      users.each do |user|
        UserMailer.news_comment_added(user, comment).deliver
      end
    end
  end
end
