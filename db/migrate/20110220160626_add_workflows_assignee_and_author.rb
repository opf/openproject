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

class AddWorkflowsAssigneeAndAuthor < ActiveRecord::Migration
  def self.up
    add_column :workflows, :assignee, :boolean, :null => false, :default => false
    add_column :workflows, :author, :boolean, :null => false, :default => false
    Workflow.update_all("assignee = #{Workflow.connection.quoted_false}")
    Workflow.update_all("author = #{Workflow.connection.quoted_false}")
  end

  def self.down
    remove_column :workflows, :assignee
    remove_column :workflows, :author
  end
end
