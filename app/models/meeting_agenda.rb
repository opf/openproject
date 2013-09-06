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

class MeetingAgenda < MeetingContent

  # TODO: internationalize the comments
  def lock!(user = User.current)
    self.comment = "Agenda closed"
    self.author = user
    self.locked = true
    self.save
  end

  def unlock!(user = User.current)
    self.comment = "Agenda opened"
    self.author = user
    self.locked = false
    self.save
  end

  def editable?
    !locked?
  end
end
