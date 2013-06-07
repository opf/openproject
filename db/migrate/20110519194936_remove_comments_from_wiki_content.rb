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

class RemoveCommentsFromWikiContent < ActiveRecord::Migration
  def self.up
    remove_column :wiki_contents, :comments
  end

  def self.down
    add_column :wiki_contents, :comments, :string
  end
end
