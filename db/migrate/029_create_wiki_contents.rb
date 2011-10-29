#-- encoding: UTF-8
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

class CreateWikiContents < ActiveRecord::Migration
  def self.up
    create_table :wiki_contents do |t|
      t.column :page_id, :integer, :null => false
      t.column :author_id, :integer
      t.column :text, :text
      t.column :comments, :string, :limit => 255, :default => ""
      t.column :updated_on, :datetime, :null => false
      t.column :version, :integer, :null => false
    end
    add_index :wiki_contents, :page_id, :name => :wiki_contents_page_id

    create_table :wiki_content_versions do |t|
      t.column :wiki_content_id, :integer, :null => false
      t.column :page_id, :integer, :null => false
      t.column :author_id, :integer
      t.column :data, :binary
      t.column :compression, :string, :limit => 6, :default => ""
      t.column :comments, :string, :limit => 255, :default => ""
      t.column :updated_on, :datetime, :null => false
      t.column :version, :integer, :null => false
    end
    add_index :wiki_content_versions, :wiki_content_id, :name => :wiki_content_versions_wcid
  end

  def self.down
    drop_table :wiki_contents
    drop_table :wiki_content_versions
  end
end
