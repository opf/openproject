class MeetingMinutes < MeetingContent
  unloadable
  
  acts_as_journalized :activity_type => 'meetings',
    :activity_permission => :view_meetings,
    :activity_find_options => {:include => {:meeting => :project}},
    :event_title => Proc.new {|o| "#{l :label_meeting_agenda}: #{o.meeting.title}"},
    :event_url => Proc.new {|o| {:controller => 'meetings', :action => 'show', :id => o.meeting}}
  
  def activity_type
    'meetings'
  end
  
  def editable?
    meeting.agenda.present? && meeting.agenda.locked?
  end
  
  protected
  
  def after_initialize
    # set defaults
    # avoid too deep stacks by not using the association helper methods
    ag = MeetingAgenda.find_by_meeting_id(meeting_id)
    self.text ||= ag.text if ag.present?
  end
  
  MeetingMinutesJournal.class_eval do
    unloadable
    
    attr_protected :data
    after_save :compress_version_text
    
    # Wiki Content might be large and the data should possibly be compressed
    def compress_version_text
      self.text = changes["text"].last if changes["text"]
      self.text ||= self.journaled.text if self.journaled.text
    end
    
    def text=(plain)
      case Setting.wiki_compression
      when "gzip"
        begin
          text_hash :text => Zlib::Deflate.deflate(plain, Zlib::BEST_COMPRESSION), :compression => Setting.wiki_compression
        rescue
          text_hash :text => plain, :compression => ''
        end
      else
        text_hash :text => plain, :compression => ''
      end
      plain
    end
    
    def text_hash(hash)
      changes.delete("text")
      changes["data"] = hash[:text]
      changes["compression"] = hash[:compression]
      update_attribute(:changes, changes.to_yaml)
    end
    
    def text
      @text ||= case changes[:compression]
      when 'gzip'
         Zlib::Inflate.inflate(data)
      else
        # uncompressed data
        changes["data"]
      end
    end
    
    def meeting
      journaled.meeting
    end
    
    def editable?
      false
    end
  end
end