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

class CreateMeetings < ActiveRecord::Migration
  def self.up
    create_table :meetings do |t|
      t.column :title, :string
      t.column :author_id, :integer
      t.column :project_id, :integer
      t.column :location, :string
      t.column :start_time, :datetime
      t.column :duration, :float

      t.timestamps
    end
  end

  def self.down
    drop_table :meetings
  end
end
