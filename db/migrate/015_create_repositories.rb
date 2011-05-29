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

class CreateRepositories < ActiveRecord::Migration
  def self.up
    create_table :repositories, :force => true do |t|
      t.column "project_id", :integer, :default => 0, :null => false
      t.column "url", :string, :default => "", :null => false
    end
  end

  def self.down
    drop_table :repositories
  end
end
