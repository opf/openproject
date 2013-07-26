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

class MeetingMinutesController < MeetingContentsController

  menu_item :meetings

  private

  def find_content
    @content = @meeting.minutes || @meeting.build_minutes
    @content_type = "meeting_minutes"
  end
end