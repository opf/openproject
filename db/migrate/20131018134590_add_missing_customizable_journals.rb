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

class AddMissingCustomizableJournals < ActiveRecord::Migration
  include Migration::Utils

  def up
    say_with_time_silently "Add missing customizable journals" do
      add_missing_customizable_journals
    end
  end

  def down
  end
end
