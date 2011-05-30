#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class CreateWikiPages < ActiveRecord::Migration
  def self.up
    create_table :wiki_pages do |t|
      t.column :wiki_id, :integer, :null => false
      t.column :title, :string, :limit => 255, :null => false
      t.column :created_on, :datetime, :null => false
    end
    add_index :wiki_pages, [:wiki_id, :title], :name => :wiki_pages_wiki_id_title
  end

  def self.down
    drop_table :wiki_pages
  end
end
