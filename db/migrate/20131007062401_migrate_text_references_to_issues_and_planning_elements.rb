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

require_relative 'migration_utils/text_references'

class MigrateTextReferencesToIssuesAndPlanningElements < ActiveRecord::Migration
  include Migration::Utils

  COLUMNS_PER_TABLE = {
    'boards' => ['description'],
    'messages' => ['content'],
    'news' => ['summary', 'description'],
    'projects' => ['description'],
    'wiki_contents' => ['text'],
    'work_packages' => ['description'],
  }

  def up
    COLUMNS_PER_TABLE.each_pair do |table, columns|
      say_with_time_silently "Update text references for table #{table}" do
        update_text_references(table, columns)
      end
    end
  end

  def down
    COLUMNS_PER_TABLE.each_pair do |table, columns|
      say_with_time_silently "Restore text references for table #{table}" do
        restore_text_references(table, columns)
      end
    end
  end
end
