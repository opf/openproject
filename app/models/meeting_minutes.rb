class MeetingMinutes < MeetingContent
  def editable?
    meeting.agenda.present? && meeting.agenda.locked?
  end
  
  def after_initialize
    # set defaults
    self.text ||= meeting.agenda.text if meeting.agenda.present?
  end
end