#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative '../../db/migrate/migration_utils/timelines'

namespace :migrations do
  namespace :timelines do
    desc "Sets all timelines with historical comparison from 'historical' to 'none'"
    task remove_timelines_historical_comparison_from_options: :environment do |_task|
      setter = TimelinesHistoricalComparisonSetter.new

      setter.remove_timelines_historical_comparison_from_options
    end

    private

    class TimelinesHistoricalComparisonSetter < ActiveRecord::Migration
      include Migration::Utils

      def remove_timelines_historical_comparison_from_options
        say_with_time_silently 'Set historical comparison to none for all timelines' do
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
