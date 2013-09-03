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

class ChangeSerializedColumnsFromStringToText < ActiveRecord::Migration
  def self.up
    change_table :my_projects_overviews do |t|
      t.change_default "left", nil
      t.change_default "right", nil
      t.change_default "top", nil
      t.change_default "hidden", nil

      t.change "left", :text, :null => false
      t.change "right", :text, :null => false
      t.change "top", :text, :null => false
      t.change "hidden", :text, :null => false
    end
  end

  def self.down
    change_table :my_projects_overviews do |t|
      t.change "left", :string, :default => ["wiki", "projectdetails", "issuetracking"].to_yaml, :null => false
      t.change "right", :string, :default => ["members", "news"].to_yaml, :null => false
      t.change "top", :string, :default => [].to_yaml, :null => false
      t.change "hidden", :string, :default => [].to_yaml, :null => false
    end
  end
end
