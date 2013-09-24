#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2011-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
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
