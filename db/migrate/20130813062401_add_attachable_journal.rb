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

class AddAttachableJournal < ActiveRecord::Migration
  def change
    create_table :attachable_journals do |t|
      t.integer :journal_id, null: false
      t.integer :attachment_id, null: false
      t.string  :filename, :default => '', :null => false
    end

    add_index :attachable_journals, :journal_id
    add_index :attachable_journals, :attachment_id
  end
end
