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
    if comment.commented.is_a?(News) && Setting.notified_events.include?('news_comment_added')
      Mailer.deliver_news_comment_added(comment)
    end
  end
end
