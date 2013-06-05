#-- encoding: UTF-8
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

class CreateQueries < ActiveRecord::Migration
  def self.up
    create_table :queries, :force => true do |t|
      t.column "project_id", :integer
      t.column "name", :string, :default => "", :null => false
      t.column "filters", :text
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "is_public", :boolean, :default => false, :null => false
    end
  end

  def self.down
    drop_table :queries
  end
end
