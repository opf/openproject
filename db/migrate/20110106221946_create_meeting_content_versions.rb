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

class CreateMeetingContentVersions < ActiveRecord::Migration
  def self.up
    MeetingContent.create_versioned_table
  end

  def self.down
    MeetingContent.drop_versioned_table
  end
end
