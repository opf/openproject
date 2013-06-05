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
