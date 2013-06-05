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

class RemoveEnumerationsOpt < ActiveRecord::Migration
  def self.up
    remove_column :enumerations, :opt
  end

  def self.down
    add_column :enumerations, :opt, :string, :limit => 4, :default => '', :null => false
    Enumeration.update_all("opt = 'IPRI'", "type = 'IssuePriority'")
    Enumeration.update_all("opt = 'DCAT'", "type = 'DocumentCategory'")
    Enumeration.update_all("opt = 'ACTI'", "type = 'TimeEntryActivity'")
  end
end
