#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
    # For instance:
    #
    #   it 'is scheduled' do
    #     expect_schedule(work_packages, <<~CHART)
    #       days     | MTWTFSS   |
    #       main     | XX        |
    #       follower |   XXX     |
    #     CHART
    #   end
    #
    # is equivalent to:
    #
    #   it 'is scheduled' do
    #     main = work_packages.find { _1.id == main.id } || main
    #     expect(main.start_date).to eq(next_monday)
    #     expect(main.due_date).to eq(next_monday + 1.day)
    #     follower = work_packages.find { _1.id == follower.id } || follower
    #     expect(follower.start_date).to eq(next_monday + 2.days)
    #     expect(follower.due_date).to eq(next_monday + 4.days)
    #   end
    def expect_schedule(work_packages, chart)
      by_id = work_packages.index_by(&:id)
      chart = Chart.for(chart)
      chart.work_packages_attributes.each do |attributes|
        name = attributes[:name]
        raise ArgumentError, "unable to find WorkPackage :#{name}" unless respond_to?(name)

        work_package = send(name)
        work_package = by_id[work_package.id] if by_id.has_key?(work_package.id)
        expect(work_package).to have_attributes(attributes.slice(:subject, :start_date, :due_date))
      end
    end
  end
end
