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

class CreateTimeEntries < ActiveRecord::Migration
  def self.up
    create_table :time_entries do |t|
      t.column :project_id,  :integer,  :null => false
      t.column :user_id,     :integer,  :null => false
      t.column :issue_id,    :integer
      t.column :hours,       :float,    :null => false
      t.column :comments,    :string,   :limit => 255
      t.column :activity_id, :integer,  :null => false
      t.column :spent_on,    :date,     :null => false
      t.column :tyear,       :integer,  :null => false
      t.column :tmonth,      :integer,  :null => false
      t.column :tweek,       :integer,  :null => false
      t.column :created_on,  :datetime, :null => false
      t.column :updated_on,  :datetime, :null => false
    end
    add_index :time_entries, [:project_id], :name => :time_entries_project_id
    add_index :time_entries, [:issue_id], :name => :time_entries_issue_id
  end

  def self.down
    drop_table :time_entries
  end
end
