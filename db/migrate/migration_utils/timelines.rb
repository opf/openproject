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

require_relative 'utils'

module Migration
  module Utils
    TimelineWithHistoricalComparison = Struct.new(:id, :from_date, :to_date)

    OPTIONS_COLUMN = 'options'
    HISTORICAL_DATE_FROM = 'compare_to_historical_one'
    HISTORICAL_DATE_TO = 'compare_to_historical_two'

    def timelines_with_historical_comparisons
      timelines = select_all <<-SQL
        SELECT id, options
        FROM timelines
        WHERE options LIKE '%comparison: historical%'
      SQL

      timelines.each_with_object([]) do |r, l|
        options = YAML.load(r[OPTIONS_COLUMN])
        from_date = options[HISTORICAL_DATE_FROM]
        to_date = options[HISTORICAL_DATE_TO]

        l << TimelineWithHistoricalComparison.new(r['id'], from_date, to_date)
      end
    end

    def update_options(callback)
      Proc.new do |row|
        timelines_opts = YAML.load(row[OPTIONS_COLUMN].to_s)
        if timelines_opts
          migrated_options = callback.call(timelines_opts.clone) unless callback.nil?

          row[OPTIONS_COLUMN] = YAML.dump(HashWithIndifferentAccess.new(migrated_options))
        end

        UpdateResult.new(row, true)
      end
    end

    def rename_columns(timelines_opts, options)
      return timelines_opts unless timelines_opts.has_key? 'columns'

      columns = timelines_opts['columns']

      columns.map! do |c|
        options.has_key?(c) ? options[c] : c
      end

      timelines_opts['columns'] = columns.uniq

      timelines_opts
    end
  end
end
