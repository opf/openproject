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

require_relative 'migration_utils/customizable_utils'

class RepairCustomizableJournals < ActiveRecord::Migration
  include Migration::Utils

  LEGACY_JOURNAL_TYPE = 'IssueJournal'
  JOURNAL_TYPE = 'WorkPackage'

  def up
    say_with_time_silently "Repair initial customizable journals" do
      repair_customizable_journal_entries(JOURNAL_TYPE, LEGACY_JOURNAL_TYPE)
    end
  end

  def down
    say_with_time_silently "Repair initial customizable journals" do
      remove_customizable_journal_entries(JOURNAL_TYPE, LEGACY_JOURNAL_TYPE)
    end
  end
end
