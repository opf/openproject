#-- encoding: UTF-8
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

class AddCustomValueCustomizedIndex < ActiveRecord::Migration
  def self.up
    add_index :custom_values, [:customized_type, :customized_id], :name => :custom_values_customized
  end

  def self.down
    remove_index :custom_values, :name => :custom_values_customized
  end
end
