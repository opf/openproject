#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the Finnlabs GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class RenameActsAsJournalizedChangesColumn < ActiveRecord::Migration
  def self.up
    # This is provided here for migrating up after the JournalDetails has been removed
    unless Object.const_defined?("JournalDetails")
      Object.const_set("JournalDetails", Class.new(ActiveRecord::Base))
    end

    change_table :journals do |t|
      t.rename :changes, :changed_data
    end

  end

  def self.down
    change_table "journals" do |t|
      t.rename :changed_data, :changes
    end

  end
end
