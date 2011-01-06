class CreateMeetingContentVersions < ActiveRecord::Migration
  def self.up
    MeetingContent.create_versioned_table
  end

  def self.down
    MeetingContent.drop_versioned_table
  end
end
