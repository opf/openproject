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

class AddMissingIndexesToIssueRelations < ActiveRecord::Migration
  def self.up
    add_index :issue_relations, :issue_from_id
    add_index :issue_relations, :issue_to_id
  end

  def self.down
    remove_index :issue_relations, :issue_from_id
    remove_index :issue_relations, :issue_to_id
  end
end
