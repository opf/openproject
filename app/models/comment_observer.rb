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
