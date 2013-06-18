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

class AddVersionsSharing < ActiveRecord::Migration
  def self.up
    add_column :versions, :sharing, :string, :default => 'none', :null => false
    add_index :versions, :sharing
  end

  def self.down
    remove_column :versions, :sharing
  end
end
