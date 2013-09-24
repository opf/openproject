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

class CreateMeetingContents < ActiveRecord::Migration
  def self.up
    create_table :meeting_contents do |t|
      t.column :type, :string
      t.column :meeting_id, :integer
      t.column :author_id, :integer
      t.column :text, :text
      t.column :comment, :string
      t.column :version, :integer

      t.timestamps
    end
  end

  def self.down
    drop_table :meeting_contents
  end
end
