class MergeMeetingContentVersionsWithJournals < ActiveRecord::Migration
  def self.up
    # The table doesn't exist on fresh installations
    if table_exists? :meeting_content_versions
      # This is provided here for migrating up after the MeetingContent::Version class has been removed
      unless MeetingContent.const_defined?("Version")
        MeetingContent.const_set("Version", Class.new(ActiveRecord::Base))
      end

      # load some classes
      MeetingAgenda
      MeetingMinutes

      # avoid touching WikiContent on journal creation
      MeetingAgendaJournal.class_exec {
        def touch_journaled_after_creation
        end
      }
      MeetingMinutesJournal.class_exec {
        def touch_journaled_after_creation
        end
      }

      cache = Hash.new{|h,k| h[k] = Hash.new{|h,k| h[k] = Hash.new{|h,k| h[k] = {}}}}
      
      MeetingContent::Version.find_by_sql('SELECT * FROM meeting_content_versions ORDER BY version ASC').each do |mcv|
        options = {:journaled_id => mcv.meeting_content_id, :created_at => mcv.created_at,
                   :user_id => mcv.author_id, :notes => mcv.comment, :activity_type => 'meetings',
                   :version => mcv.version}
        ft = [cache[mcv.meeting_content_id][mcv.versioned_type][mcv.version-1][:locked], mcv.locked]
        options[:changes] = {'locked' => ft} unless mcv.version == 1 || ft.first == ft.last
        journal = case mcv.versioned_type
        when 'MeetingAgenda'
          MeetingAgendaJournal.create! options
        when 'MeetingMinutes'
          MeetingMinutesJournal.create! options
        end
        journal.text = mcv.text unless mcv.text == cache[mcv.meeting_content_id][mcv.versioned_type][mcv.version-1][:text]
        cache[mcv.meeting_content_id][mcv.versioned_type][mcv.version] = {:text => mcv.text, :locked => mcv.locked}
      end
            
      drop_table :meeting_content_versions
    end
    
    change_table :meeting_contents do |t|
      t.rename :version, :lock_version
      t.remove :comment
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Can't revert to pre-journalized versioning model"
  end
end
