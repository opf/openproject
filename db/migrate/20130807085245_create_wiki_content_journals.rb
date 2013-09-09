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

class CreateWikiContentJournals < ActiveRecord::Migration
  def change
    create_table :wiki_content_journals do |t|
      t.integer  :journal_id,                         :null => false
      t.integer  :page_id,                            :null => false
      t.integer  :author_id
      t.text     :text,         :limit => 2147483647
      t.datetime :updated_on,                         :null => false
      t.integer  :lock_version,                       :null => false
    end
  end
end
