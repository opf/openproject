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

class PrepareJournalsForActsAsJournalized < ActiveRecord::Migration
  def self.up
    # This is provided here for migrating up after the JournalDetails has been removed
    unless Object.const_defined?("JournalDetails")
      Object.const_set("JournalDetails", Class.new(ActiveRecord::Base))
    end

    change_table :journals do |t|
      t.rename :journalized_id, :journaled_id
      t.rename :created_on, :created_at

      t.integer :version, :default => 0, :null => false
      t.string :activity_type
      t.text :changes
      t.string :type

      t.index :journaled_id
      t.index :activity_type
      t.index :created_at
      t.index :type
    end

  end

  def self.down
    change_table "journals" do |t|
      t.rename :journaled_id, :journalized_id
      t.rename :created_at, :created_on

      t.remove_index :journaled_id
      t.remove_index :activity_type
      t.remove_index :created_at
      t.remove_index :type

      t.remove :type
      t.remove :version
      t.remove :activity_type
      t.remove :changes
    end

  end
end
