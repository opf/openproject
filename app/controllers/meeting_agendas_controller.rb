#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class MeetingAgendasController < MeetingContentsController
  unloadable

  menu_item :meetings

  def close
    @meeting.close_agenda_and_copy_to_minutes!

    redirect_back_or_default :controller => 'meetings', :action => 'show', :id => @meeting
  end

  def open
    @content.unlock!
    redirect_back_or_default :controller => 'meetings', :action => 'show', :id => @meeting
  end

  private

  def find_content
    @content = @meeting.agenda || @meeting.build_agenda
    @content_type = "meeting_agenda"
  end
end
