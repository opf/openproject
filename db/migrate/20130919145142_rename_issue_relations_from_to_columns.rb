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

class RenameIssueRelationsFromToColumns < ActiveRecord::Migration
  def change
    rename_column :issue_relations, :issue_from_id, :from_id
    rename_column :issue_relations, :issue_to_id, :to_id
  end
end
