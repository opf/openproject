#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# Sample plugin migration
# Use rake db:migrate_plugins to migrate installed plugins
class CreateMeetings < ActiveRecord::Migration
  def self.up
    create_table :meetings do |t|
      t.column :project_id, :integer, :null => false
      t.column :description, :string
      t.column :scheduled_on, :datetime
    end
  end

  def self.down
    drop_table :meetings
  end
end
