class MeetingMinutes < MeetingContent
  def editable?
    meeting.agenda.present? && meeting.agenda.locked?
  end
  
  # Compatibility for mailer.rb
  def updated_on
    updated_at
  end
    
  protected
  
  def after_initialize
    # set defaults
    self.text ||= meeting.agenda.text if meeting.present? && meeting.agenda.present?
    super
  end
end