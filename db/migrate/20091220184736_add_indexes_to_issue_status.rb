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

class AddIndexesToIssueStatus < ActiveRecord::Migration
  def self.up
    add_index :issue_statuses, :position
    add_index :issue_statuses, :is_closed
    add_index :issue_statuses, :is_default
  end

  def self.down
    remove_index :issue_statuses, :position
    remove_index :issue_statuses, :is_closed
    remove_index :issue_statuses, :is_default
  end
end
