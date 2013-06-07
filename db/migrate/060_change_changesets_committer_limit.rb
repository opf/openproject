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

class ChangeChangesetsCommitterLimit < ActiveRecord::Migration
  def self.up
    change_column :changesets, :committer, :string, :limit => nil
  end

  def self.down
    change_column :changesets, :committer, :string, :limit => 30
  end
end
