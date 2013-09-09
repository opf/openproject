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

class CreateTimeEntryJournals < ActiveRecord::Migration
  def change
    create_table :time_entry_journals do |t|
      t.integer  :journal_id,      :null => false
      t.integer  :project_id,      :null => false
      t.integer  :user_id,         :null => false
      t.integer  :work_package_id
      t.float    :hours,           :null => false
      t.string   :comments
      t.integer  :activity_id,     :null => false
      t.date     :spent_on,        :null => false
      t.integer  :tyear,           :null => false
      t.integer  :tmonth,          :null => false
      t.integer  :tweek,           :null => false
      t.datetime :created_on,      :null => false
      t.datetime :updated_on,      :null => false
    end
  end
end
