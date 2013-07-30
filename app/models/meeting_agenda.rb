#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class MeetingAgenda < MeetingContent
  unloadable

  acts_as_journalized :activity_type => 'meetings',
    :activity_permission => :view_meetings,
    :activity_find_options => {:include => {:meeting => :project}},
    :event_title => Proc.new {|o| "#{l :label_meeting_agenda}: #{o.meeting.title}"},
    :event_url => Proc.new {|o| {:controller => 'meetings', :action => 'show', :id => o.meeting}}

  def activity_type
    'meetings'
  end

  # TODO: internationalize the comments
  def lock!(user = User.current)
    self.comment = "Agenda closed"
    self.author = user
    self.locked = true
    self.save
  end

  def unlock!(user = User.current)
    self.comment = "Agenda opened"
    self.author = user
    self.locked = false
    self.save
  end

  def editable?
    !locked?
  end

  MeetingAgendaJournal.class_eval do
    unloadable

    attr_protected :data
    after_save :compress_version_text

    # Wiki Content might be large and the data should possibly be compressed
    def compress_version_text
      self.text = changed_data["text"].last if changed_data["text"]
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
      changed_data.delete("text")
      changed_data["data"] = hash[:text]
      changed_data["compression"] = hash[:compression]
      update_attribute(:changed_data, changed_data)
      # changed_data = changed_data
    end

    def text
      @text ||= case changed_data[:compression]
      when 'gzip'
         Zlib::Inflate.inflate(data)
      else
        # uncompressed data
        changed_data["data"]
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
