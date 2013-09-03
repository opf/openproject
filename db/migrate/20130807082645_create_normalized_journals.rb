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

class CreateNormalizedJournals < ActiveRecord::Migration
  def change
    create_table :journals do |t|
      t.references :journable, polymorphic: true
      t.references :journable_data, polymorphic: true
      t.integer  :user_id, :default => 0, :null => false
      t.text     :notes
      t.datetime :created_at, :null => false
      t.integer  :version, :default => 0, :null => false
      t.string   :activity_type
    end
  end
end
