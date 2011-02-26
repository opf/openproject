class MeetingAgenda < MeetingContent
  def lock!
    update_attribute :locked, true
  end
  
  def unlock!
    update_attribute :locked, false
  end
  
  def editable?
    !locked?
  end
end