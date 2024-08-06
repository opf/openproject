#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

module ScheduleHelpers
  module LetSchedule
    # Declare work packages and relations from a visual chart representation.
    #
    # It uses +create_schedule+ internally and is useful to have direct access
    # to the created work packages.
    #
    # For instance:
    #
    #   let_schedule(<<~CHART)
    #     days       | MTWTFSS   |
    #     main       | XX        |
    #     follower   |   XXX     | follows main
    #     start_only |  [        |
    #     due_only   |    ]      |
    #   CHART
    #
    # is equivalent to:
    #
    #   let!(:schedule) do
    #     create_schedule(chart)
    #   end
    #   let(:main) do
    #     schedule.work_package(:main)
    #   end
    #   let(:follower) do
    #     schedule.work_package(:follower)
    #   end
    #   let(:start_only) do
    #     schedule.work_package(:start_only)
    #   end
    #   let(:due_only) do
    #     schedule.work_package(:due_only)
    #   end
    def let_schedule(chart_representation)
      # To be able to use `travel_to` in a before hook, the dates in the chart
      # must be lazy evaluated in a let statement.
      let!(:schedule) { create_schedule(chart_representation) }

      chart = Chart.for(chart_representation)
      chart.work_package_names.each do |name|
        let(name) { schedule.work_package(name) }
      end
    end
  end
end
