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

class AddCustomizableJournal < ActiveRecord::Migration
  def change
    create_table :customizable_journals do |t|
      t.integer :journal_id, null: false
      t.integer :custom_field_id, null: false
      t.string  :value, :default_value
    end

    add_index :customizable_journals, :journal_id
    add_index :customizable_journals, :custom_field_id
  end
end
