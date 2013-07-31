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

class IncreaseJournalsChangedDataLimit < ActiveRecord::Migration
  def up

    # fixes the inconsistency introduced in
    # 20091227112908_change_wiki_contents_text_limit.rb, which
    # previously resulted in journal changed_data having stricter
    # limitations than wiki contents.

    max_size = 16.megabytes

    change_column :journals,
                  :changed_data,
                  :text,
                  :limit => max_size

    change_column :journal_details,
                  :value,
                  :text,
                  :limit => max_size

    change_column :journal_details,
                  :old_value,
                  :text,
                  :limit => max_size

  end

  def down

    change_column :journals,
                  :changed_data,
                  :text

    change_column :journal_details,
                  :value,
                  :text

    change_column :journal_details,
                  :old_value,
                  :text

  end
end
