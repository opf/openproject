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

class AddProjectsOverviews < ActiveRecord::Migration
  def self.up
    create_table :my_projects_overviews, :force => true do |t|
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "left", :string, :default => ["wiki", "projectdetails", "issuetracking"].to_yaml, :null => false
      t.column "right", :string, :default => ["members", "news"].to_yaml, :null => false
      t.column "top", :string, :default => [].to_yaml, :null => false
      t.column "hidden", :string, :default => [].to_yaml, :null => false
      t.column "created_on", :datetime, :null => false
    end
  end

  def self.down
    drop_table :my_projects_overviews
  end
end
