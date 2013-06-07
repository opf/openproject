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

class SetLanguageLengthToFive < ActiveRecord::Migration
  def self.up
    change_column :users, :language, :string, :limit => 5, :default => ""
  end

  def self.down
    raise IrreversibleMigration
  end
end
