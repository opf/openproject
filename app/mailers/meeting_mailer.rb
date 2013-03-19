class MeetingMailer < UserMailer

  def content_for_review(user, content, content_type)
    @meeting = content.meeting
    @meeting_url = meeting_url @meeting
    @project_url = project_url @meeting.project
    @content_type = content_type

    open_project_headers 'Project' => @meeting.project.identifier,
                         'Meeting-Id' => @meeting.id

    subject = "[#{@meeting.project.name}] #{I18n.t(:"label_meeting_#{content_type}")}: #{@meeting.title}"
    mail :to => user.mail, :cc => @meeting.watcher_recipients, :subject => subject
  end
end
