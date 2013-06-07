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

class AddSummaryToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :summary, :text
  end

  def self.down
    remove_column :projects, :summary
  end
end
