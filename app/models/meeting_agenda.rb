class MeetingAgenda < MeetingContent
  
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
end