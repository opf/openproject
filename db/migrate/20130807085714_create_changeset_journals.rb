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

class CreateChangesetJournals < ActiveRecord::Migration
  def change
    create_table :changeset_journals do |t|
      t.integer  :journal_id,    :null => false
      t.integer  :repository_id, :null => false
      t.string   :revision,      :null => false
      t.string   :committer
      t.datetime :committed_on,  :null => false
      t.text     :comments
      t.date     :commit_date
      t.string   :scmid
      t.integer  :user_id
    end
  end
end
