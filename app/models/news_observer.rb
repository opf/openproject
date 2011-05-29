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

class NewsObserver < ActiveRecord::Observer
  def after_create(news)
    Mailer.deliver_news_added(news) if Setting.notified_events.include?('news_added')
  end
end
