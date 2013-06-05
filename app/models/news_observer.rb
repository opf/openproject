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

class NewsObserver < ActiveRecord::Observer
  def after_create(news)
    if Setting.notified_events.include?('news_added')
      users = User.find_all_by_mails(news.recipients)
      users.each do |user|
        UserMailer.news_added(user, news).deliver
      end
    end
  end
end
