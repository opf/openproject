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

class RemoveMeetingRoleIdFromMeetingParticipants < ActiveRecord::Migration
  def up
    remove_column :meeting_participants, :meeting_role_id
  end

  def down
    add_column :meeting_participants, :meeting_role_id, :integer
  end
end
