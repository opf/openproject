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

class CreateMeetingParticipants < ActiveRecord::Migration
  def self.up
    create_table :meeting_participants do |t|
      t.column :user_id, :integer
      t.column :meeting_id, :integer
      t.column :meeting_role_id, :integer
      t.column :email, :string
      t.column :name, :string
      t.column :invited, :boolean
      t.column :attended, :boolean
      
      t.timestamps
    end
  end

  def self.down
    drop_table :meeting_participants
  end
end
