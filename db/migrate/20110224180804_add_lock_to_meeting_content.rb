class AddLockToMeetingContent < ActiveRecord::Migration
  def self.up
    add_column :meeting_contents, :locked, :boolean, :default => false
    # Check for existence of the pre-journalized MeetingContentVersions table
    add_column :meeting_content_versions, :locked, :boolean, :default => nil if table_exists? :meeting_content_versions
  end

  def self.down
    remove_column :meeting_contents, :locked
    # Check for existence of the pre-journalized MeetingContentVersions table
    remove_column :meeting_content_versions, :locked if table_exists? :meeting_content_versions
  end
end
