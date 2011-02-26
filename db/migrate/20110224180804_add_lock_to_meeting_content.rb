class AddLockToMeetingContent < ActiveRecord::Migration
  def self.up
    add_column :meeting_contents, :locked, :boolean, :default => false
    add_column :meeting_content_versions, :locked, :boolean, :default => nil
  end

  def self.down
    remove_column :meeting_contents, :locked
    remove_column :meeting_content_versions, :locked
  end
end
