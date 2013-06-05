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

class CreateWikiRedirects < ActiveRecord::Migration
  def self.up
    create_table :wiki_redirects do |t|
      t.column :wiki_id, :integer, :null => false
      t.column :title, :string
      t.column :redirects_to, :string
      t.column :created_on, :datetime, :null => false
    end
    add_index :wiki_redirects, [:wiki_id, :title], :name => :wiki_redirects_wiki_id_title
  end

  def self.down
    drop_table :wiki_redirects
  end
end
