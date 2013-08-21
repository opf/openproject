#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2011-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class MeetingMailer < UserMailer

  def content_for_review(content, content_type)
    @meeting = content.meeting
    @meeting_url = meeting_url @meeting
    @project_url = project_url @meeting.project
    @content_type = content_type

    open_project_headers 'Project' => @meeting.project.identifier,
                         'Meeting-Id' => @meeting.id

    recipients = @meeting.watcher_recipients.reject{|r| r == @meeting.author.mail}

    subject = "[#{@meeting.project.name}] #{I18n.t(:"label_#{content_type}")}: #{@meeting.title}"
    mail :to => @meeting.author.mail, :cc => recipients, :subject => subject
  end
end
