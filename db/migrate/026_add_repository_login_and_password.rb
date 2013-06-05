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

class AddRepositoryLoginAndPassword < ActiveRecord::Migration
  def self.up
    add_column :repositories, :login, :string, :limit => 60, :default => ""
    add_column :repositories, :password, :string, :limit => 60, :default => ""
  end

  def self.down
    remove_column :repositories, :login
    remove_column :repositories, :password
  end
end
