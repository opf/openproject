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

class CreateWikiMenuItems < ActiveRecord::Migration
  def self.up
    create_table :wiki_menu_items do |t|
      t.column :name, :string
      t.column :title, :string
      t.column :parent_id, :integer
      t.column :options, :text

      t.belongs_to :wiki
    end
  end

  def self.down
    puts "You cannot safely undo this migration!"
  end
end
