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
