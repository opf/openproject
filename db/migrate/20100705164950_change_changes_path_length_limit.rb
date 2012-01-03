#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
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
