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

class CreateWikis < ActiveRecord::Migration
  def self.up
    create_table :wikis do |t|
      t.column :project_id, :integer, :null => false
      t.column :start_page, :string,  :limit => 255, :null => false
      t.column :status, :integer, :default => 1, :null => false
    end
    add_index :wikis, :project_id, :name => :wikis_project_id
  end

  def self.down
    drop_table :wikis
  end
end
