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
  module LetSchedule
    # Declare work packages and relations from a visual chart representation.
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
    #   let!(:schedule_chart) do
    #     chart = <...parse_chart(CHART)...>
    #     main
    #     follower
    #     start_only
    #     due_only
    #     relation_follower_follows_main
    #     chart
    #   end
    #   let(:main) do
    #     create(:work_package, subject: 'main', start_date: next_monday, due_date: next_monday + 1.day)
    #   end
    #   let(:follower) do
    #     create(:work_package, subject: 'follower', start_date: next_monday + 2.days, due_date: next_monday + 4.days) }
    #   end
    #   let(:relation_follower_follows_main) do
    #     create(:follows_relation, from: follower, to: main, delay: 0) }
    #   end
    #   let(:start_only) do
    #     create(:work_package, subject: 'start_only', start_date: next_monday + 1.day) }
    #   end
    #   let(:due_only) do
    #     create(:work_package, subject: 'due_only', due_date: next_monday + 3.days) }
    #   end
    def let_schedule(chart_representation, **extra_attributes)
      # To be able to use `travel_to` in a before hook, the dates in the chart
      # must be lazy evaluated in a let statement.
      let(:schedule_chart) { Chart.for(chart_representation) }
      let!(:__evaluate_work_packages_from_schedule_chart) do
        schedule_chart.work_package_names.each do |name|
          # force evaluation of work package
          send(name)
          schedule_chart.predecessors_by_follower(name).each do |predecessor|
            # force evaluation of relation
            send("relation_#{name}_follows_#{predecessor}")
          end
        end
      end

      # we still need to parse the chart to get the work package names and relations
      chart = Chart.for(chart_representation)
      chart.work_package_names.each do |name|
        let(name) do
          attributes = schedule_chart
            .work_package_attributes(name)
            .excluding(:name)
            .reverse_merge(extra_attributes)
            .merge(parent: schedule_chart.parent(name) ? send(schedule_chart.parent(name)) : nil)
          create(:work_package, attributes)
        end
        chart.predecessors_by_follower(name).each do |predecessor|
          relation_alias = "relation_#{name}_follows_#{predecessor}"
          let(relation_alias) do
            create(:follows_relation,
                   from: send(name),
                   to: send(predecessor),
                   delay: schedule_chart.delay_between(predecessor:, follower: name))
          end
        end
      end
    end
  end
end
