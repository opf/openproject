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

class AddIndexOnChangesetsScmid < ActiveRecord::Migration
  def self.up
    add_index :changesets, [:repository_id, :scmid], :name => :changesets_repos_scmid
  end

  def self.down
    remove_index :changesets, :name => :changesets_repos_scmid
  end
end
