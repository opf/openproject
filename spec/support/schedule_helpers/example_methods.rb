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
  module ExampleMethods
    # Create work packages and relations from a visual chart representation.
    #
    # For instance:
    #
    #   create_schedule(<<~CHART)
    #     days       | MTWTFSS |
    #     main       | XX      |
    #     follower   |   XXX   | follows main
    #     start_only |  [      |
    #     due_only   |    ]    |
    #   CHART
    #
    # is equivalent to:
    #
    #   create(:work_package, subject: 'main', start_date: next_monday, due_date: next_monday + 1.day)
    #   create(:work_package, subject: 'follower', start_date: next_monday + 2.days, due_date: next_monday + 4.days) }
    #   create(:work_package, subject: 'start_only', start_date: next_monday + 1.day) }
    #   create(:work_package, subject: 'due_only', due_date: next_monday + 3.days) }
    #   create(:follows_relation, from: follower, to: main, lag: 0) }
    #
    def create_schedule(chart_representation)
      chart = Chart.for(chart_representation)
      ScheduleBuilder.from_chart(chart)
    end

    # Change the given work packages according to the given chart representation.
    # Work packages are changed without being saved.
    #
    # For instance:
    #
    #   before do
    #     change_schedule([main], <<~CHART)
    #       days | MTWTFSS |
    #       main | XX      |
    #     CHART
    #   end
    #
    # is equivalent to:
    #
    #   before do
    #     main.start_date = monday
    #     main.due_date = tuesday
    #   end
    def change_schedule(work_packages, chart)
      Chart.for(chart).work_packages_attributes.each do |attributes|
        work_package = work_packages.find { |wp| wp.subject == attributes[:subject] }
        unless work_package
          raise ArgumentError, "no work package with subject #{attributes[:subject]} given; " \
                               "available work packages are #{work_packages.pluck(:subject).to_sentence}"
        end

        attributes.slice(:start_date, :due_date).each do |attribute, value|
          work_package.send(:"#{attribute}=", value)
        end
      end
    end

    # Expect the given work packages to match a visual chart representation.
    #
    # It uses +match_schedule+ internally.
    #
    # For instance:
    #
    #   it 'is scheduled' do
    #     expect_schedule(work_packages, <<~CHART)
    #       days     | MTWTFSS |
    #       main     | XX      |
    #       follower |   XXX   |
    #     CHART
    #   end
    #
    # is equivalent to:
    #
    #   it 'is scheduled' do
    #     expect(work_packages).to match_schedule(<<~CHART)
    #       days     | MTWTFSS |
    #       main     | XX      |
    #       follower |   XXX   |
    #     CHART
    #   end
    def expect_schedule(work_packages, chart)
      expect(work_packages).to match_schedule(chart)
    end
  end
end
