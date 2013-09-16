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

class DropModelJournalsUpdatedOnColumn < ActiveRecord::Migration
  def up
    remove_column :work_package_journals, :updated_at
    remove_column :wiki_content_journals, :updated_on
    remove_column :time_entry_journals, :updated_on
    remove_column :message_journals, :updated_on
  end

  def down
    add_column :work_package_journals, :updated_at, :datetime
    add_column :wiki_content_journals, :updated_on, :datetime
    add_column :time_entry_journals, :updated_on, :datetime
    add_column :message_journals, :updated_on, :datetime
  end
end
