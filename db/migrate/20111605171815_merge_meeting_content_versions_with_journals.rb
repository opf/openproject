class MergeMeetingContentVersionsWithJournals < ActiveRecord::Migration
  def self.up
    # The table doesn't exist on fresh installations
    if table_exists? :meeting_content_versions
      # This is provided here for migrating up after the MeetingContent::Version class has been removed
      unless MeetingContent.const_defined?("Version")
        MeetingContent.const_set("Version", Class.new(ActiveRecord::Base))
      end
      
      # Make sure the journalized classes are explicitely loaded
      MeetingAgenda
      MeetingMinutes
      
      MeetingContent::Version.find_by_sql("SELECT * FROM meeting_content_versions").each do |mcv|
        options = {:journaled_id => mcv.meeting_content_id, :created_at => mcv.created_at, 
                   :user_id => mcv.author_id, :notes => mcv.comment, :activity_type => "meetings"}
        journal = case mcv.versioned_type
        when 'MeetingAgenda'
          MeetingAgendaJournal.create! options
        when 'MeetingMinutes'
          MeetingMinutesJournal.create! options
        end
        changes = {}
        changes["text"] = mcv.text
        changes["locked"] = mcv.locked
        journal.update_attribute(:changes, changes.to_yaml)
        journal.update_attribute(:version, mcv.version)
      end
            
      drop_table :meeting_content_versions
    end
    
    change_table :meeting_contents do |t|
      t.rename :version, :lock_version
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Can't revert to pre-journalized versioning model"
  end
end
