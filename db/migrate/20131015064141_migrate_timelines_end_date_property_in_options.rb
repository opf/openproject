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

require 'yaml'

require_relative 'migration_utils/utils'

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
                           update_options(OPTIONS),
                           options_filter(OPTIONS.keys))
    end
  end

  def down
    say_with_time_silently "Restore timelines options" do
      update_column_values('timelines',
                           [COLUMN],
                           update_options(OPTIONS.invert),
                           options_filter(OPTIONS.invert.keys))
    end
  end

  private

  def options_filter(options)
    filter([COLUMN], options)
  end

  def update_options(options)
    Proc.new do |row|
      timelines_opts = YAML.load(row[COLUMN])

      renamed_options = timelines_opts.each_with_object({}) do |(k, v), h|
        new_key = (options.has_key? k) ? options[k] : k
        h[new_key] = update_option_value(v)
      end

      row[COLUMN] = YAML.dump(renamed_options)

      UpdateResult.new(row, true)
    end
  end

  def update_option_value(value)
    if value.kind_of? Array
      value.map{|e| (OPTIONS.has_key? e) ? OPTIONS[e] : e}
    elsif OPTIONS.has_key? value
      OPTIONS[value]
    else
      value
    end
  end
end
