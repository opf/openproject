class MeetingMinutes < MeetingContent
  def editable?
    meeting.agenda.present? && meeting.agenda.locked?
  end
  
  protected
  
  def after_initialize
    # set defaults
    self.text ||= meeting.agenda.text if meeting.present? && meeting.agenda.present?
    super
  end
end