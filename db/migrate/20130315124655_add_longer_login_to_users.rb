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

class AddLongerLoginToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.change "login", :string, :limit => 256, :default => "", :null => false
    end
  end

  def self.down
    change_table :users do |t|
      t.change "login", :string, :limit => 30, :default => "", :null => false
    end
  end
end
