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

class MoveJournalsToLegacyJournals < ActiveRecord::Migration
  def up
    rename_table :journals, :legacy_journals
  end

  def down
    rename_table :legacy_journals, :journals
  end
end
