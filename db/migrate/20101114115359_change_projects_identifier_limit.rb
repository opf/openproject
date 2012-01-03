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

class ChangeProjectsIdentifierLimit < ActiveRecord::Migration
  def self.up
    change_column :projects, :identifier, :string, :limit => nil
  end

  def self.down
    change_column :projects, :identifier, :string, :limit => 20
  end
end
