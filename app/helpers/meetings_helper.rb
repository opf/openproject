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

module MeetingsHelper
  def format_participant_list(participants)
    participants.sort.collect{|p| link_to_user p.user}.join("; ").html_safe
  end
end
