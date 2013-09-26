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

class RenameIssueRelationsToRelations < ActiveRecord::Migration
  def up
    rename_table :issue_relations, :relations

    rename_column :relations, :issue_from_id, :from_id
    rename_column :relations, :issue_to_id, :to_id
  end

  def down
    rename_column :relations, :from_id, :issue_from_id
    rename_column :relations, :to_id, :issue_to_id

    rename_table :relations, :issue_relations
  end
end
