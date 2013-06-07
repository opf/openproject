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

class CreateChanges < ActiveRecord::Migration
  def self.up
    create_table :changes do |t|
      t.column :changeset_id, :integer, :null => false
      t.column :action, :string,  :limit => 1, :default => "", :null => false
      t.column :path, :string, :default => "", :null => false
      t.column :from_path, :string
      t.column :from_revision, :integer
    end
    add_index :changes, [:changeset_id], :name => :changesets_changeset_id
  end

  def self.down
    drop_table :changes
  end
end
