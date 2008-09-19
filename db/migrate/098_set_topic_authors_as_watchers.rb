class SetTopicAuthorsAsWatchers < ActiveRecord::Migration
  def self.up
    # Sets active users who created/replied a topic as watchers of the topic
    # so that the new watch functionality at topic level doesn't affect notifications behaviour
    Message.connection.execute("INSERT INTO watchers (watchable_type, watchable_id, user_id)" +
                                 " SELECT DISTINCT 'Message', COALESCE(messages.parent_id, messages.id), messages.author_id FROM messages, users" +
                                 " WHERE messages.author_id = users.id AND users.status = 1")
  end

  def self.down
    # Removes all message watchers
    Watcher.delete_all("watchable_type = 'Message'")
  end
end
