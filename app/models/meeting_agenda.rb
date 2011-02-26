class MeetingAgenda < MeetingContent
  def lock!
    update_attribute :locked, true
  end
end