class MeetingMinutes < MeetingContent
  
  acts_as_journalized :except => ['comment'], :activity_type => 'meetings'
  
  def editable?
    meeting.agenda.present? && meeting.agenda.locked?
  end
  
  protected
  
  def after_initialize
    # set defaults
    # avoid too deep stacks by not using the association helper methods
    ag = MeetingAgenda.find_by_meeting_id(meeting_id)
    self.text ||= ag.text if ag.present?
    super
  end
end