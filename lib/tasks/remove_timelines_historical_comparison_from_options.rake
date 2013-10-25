#-- encoding: UTF-8
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

require_relative '../../db/migrate/migration_utils/timelines'

namespace :migrations do
  namespace :timelines do



    desc "Sets all timelines with historical comparison from 'historical' to 'none'"
    task :remove_timelines_historical_comparison_from_options => :environment do |task|
      setter = TimelinesHistoricalComparisonSetter.new

      setter.remove_timelines_historical_comparison_from_options
    end

    private

    class TimelinesHistoricalComparisonSetter < ActiveRecord::Migration
      include Migration::Utils

      def remove_timelines_historical_comparison_from_options
        say_with_time_silently "Set historical comparison to none for all timelines" do
          update_column_values('timelines',
                               ['options'],
                               update_options(set_historical_comparison_to_none),
                               historical_comparison_filter)
        end
      end

      private

      def set_historical_comparison_to_none
        Proc.new do |timelines_opts|
          timelines_opts['comparison'] = 'none'
          timelines_opts
        end
      end

      def historical_comparison_filter
        "options LIKE '%comparison: historical%'"
      end
    end
  end
end
