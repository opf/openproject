class MeetingAgenda < MeetingContent
  unloadable
  
  acts_as_journalized :activity_type => 'meetings'
  
  # TODO: internationalize the comments
  def lock!(user = User.current)
    update_attributes :locked => true, :author => user, :comment => "Agenda closed"
  end
  
  def unlock!(user = User.current)
    update_attributes :locked => false, :author => user, :comment => "Agenda opened"
  end
  
  def editable?
    !locked?
  end
  
  MeetingAgendaJournal.class_eval do
    attr_protected :data
    after_save :compress_version_text
    
    # Wiki Content might be large and the data should possibly be compressed
    def compress_version_text
      self.text = changes["text"].last if changes["text"]
      self.text ||= self.journaled.text
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