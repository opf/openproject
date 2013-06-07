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

class ChangeChangesPathLengthLimit < ActiveRecord::Migration
  def self.up
    # these are two steps to please MySQL 5 on Win32
    change_column :changes, :path, :text, :default => nil, :null => true
    change_column :changes, :path, :text, :null => false

    change_column :changes, :from_path, :text
  end

  def self.down
    change_column :changes, :path, :string, :default => "", :null => false
    change_column :changes, :from_path, :string
  end
end
