module ActivityHelper
  def event_icon(event)
    # meeting_agenda and meeting_minutes
    if event.event_type.start_with?('meeting')
      'meetings'
    # project_attributes
    elsif event.event_type.start_with?('project')
      'projects'
    else
      event.event_type
    end
  end

  def journal_rendered_details(journal)
    journal.details
      .map { |detail| journal.render_detail(detail) }
      .compact
  end
end
