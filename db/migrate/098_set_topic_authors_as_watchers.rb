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

class SetTopicAuthorsAsWatchers < ActiveRecord::Migration
  def self.up
    # Sets active users who created/replied a topic as watchers of the topic
    # so that the new watch functionality at topic level doesn't affect notifications behaviour
    Message.connection.execute("INSERT INTO #{Watcher.table_name} (watchable_type, watchable_id, user_id)" +
                                 " SELECT DISTINCT 'Message', COALESCE(m.parent_id, m.id), m.author_id" +
                                 " FROM #{Message.table_name} m, #{User.table_name} u" +
                                 " WHERE m.author_id = u.id AND u.status = 1")
  end

  def self.down
    # Removes all message watchers
    Watcher.delete_all("watchable_type = 'Message'")
  end
end
