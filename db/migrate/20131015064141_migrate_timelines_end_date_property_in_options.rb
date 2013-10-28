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

require_relative 'migration_utils/timelines'

class MigrateTimelinesEndDatePropertyInOptions < ActiveRecord::Migration
  include Migration::Utils

  COLUMN = 'options'

  OPTIONS = {
    "end_date" => "due_date"
  }

  def up
    say_with_time_silently "Update timelines options" do
      update_column_values('timelines',
                           [COLUMN],
                           update_options(migrate_end_date_options(OPTIONS)),
                           options_filter(OPTIONS.keys))
    end
  end

  def down
    say_with_time_silently "Restore timelines options" do
      update_column_values('timelines',
                           [COLUMN],
                           update_options(migrate_end_date_options(OPTIONS.invert)),
                           options_filter(OPTIONS.invert.keys))
    end
  end

  private

  def options_filter(options)
    filter([COLUMN], options)
  end

  def migrate_end_date_options(options)
    Proc.new do |timelines_opts|
      opts = rename_columns(timelines_opts, options)

      opts
    end
  end
end
