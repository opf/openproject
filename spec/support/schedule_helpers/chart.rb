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
  # Contains work packages and relations information from a chart
  # representation.
  #
  # The work package information are:
  # * subject
  # * start_date
  # * due_date
  #
  # The relations information are limited to follows relations and are retrieved
  # with +#predecessors_by_follower+
  #
  # The chart uses different symbols in the timeline to represent a work package
  # start and due dates:
  # * +X+: a day of the work package duration. The first +X+ is the start date,
  #   the last +X+ is the due date.
  # * +[+: the work package start date. Can be used instead of +X+ when the work
  #   package has no due date.
  # * +]+: the work package due date. Can be used instead of +X+ when the work
  #   package has no start date.
  # * +_+: ignored but useful as a placeholder to highlight particular days, for
  #   instance to highlight the previous dates of a work package.
  class Chart
    attr_reader :first_day, :last_day, :monday

    def self.for(representation)
      builder = ChartBuilder.new
      builder.parse(representation)
    end

    def self.from_work_packages(work_packages)
      ChartBuilder.new.use_work_packages(Array(work_packages))
    end

    def initialize
      self.monday = next_monday
    end

    # Sets the origin of the calendar, represented by +M+ on the first line (M as
    # in Monday).
    def monday=(monday)
      raise ArgumentError, "#{monday} is not a Monday" unless monday.wday == 1

      extend_calendar_range(monday, monday + 6.days)
      @monday = monday
    end

    def validate
      work_packages.each_key do |follower|
        predecessors_by_follower(follower).each do |predecessor|
          if !work_packages.has_key?(predecessor)
            raise "unable to find predecessor #{predecessor.inspect} " \
                  "in property \"follows #{predecessor}\" " \
                  "for work package #{follower.inspect}"
          end
        end
      end
    end

    def work_packages
      @work_packages ||= {}
    end

    def work_package_attributes(name)
      work_packages[name.to_sym]
    end

    def delay_between(predecessor:, follower:)
      delays_between.fetch([predecessor, follower])
    end

    def predecessors_by_follower(follower)
      @predecessors_by_follower ||= Hash.new { |h, k| h[k] = [] }
      @predecessors_by_follower[follower]
    end

    def add_work_package(attributes)
      name = attributes[:subject].to_sym
      extend_calendar_range(*attributes.values_at(:start_date, :due_date))
      work_packages[name] = attributes
    end

    def add_follows_relation(predecessor:, follower:, delay:)
      predecessors_by_follower(follower) << predecessor
      delays_between[[predecessor, follower]] = delay
    end

    def to_s
      representer = ChartRepresenter.new
      representer.add_row
      representer.add_cell('days')
      representer.add_cell(spaced_at(monday, 'MTWTFSS'))
      work_packages.each do |name, attributes|
        representer.add_row
        representer.add_cell(name.to_s)
        representer.add_cell(span(attributes))
      end
      representer.to_s
    end

    private

    def extend_calendar_range(*dates)
      @first_day = [@first_day, *dates].compact.min
      @last_day = [@last_day, *dates].compact.max
    end

    def spaced_at(date, text)
      nb_days = date - first_day
      (" " * nb_days) + text
    end

    def span(attributes)
      case attributes
      in { start_date: nil, due_date: nil }
        ''
      in { start_date:, due_date: nil }
        spaced_at(start_date, '[')
      in { start_date: nil, due_date: }
        spaced_at(due_date, ']')
      in { start_date:, due_date: }
        days = WorkPackages::Shared::WorkingDays.new
        span = (start_date..due_date).map do |date|
          days.working?(date) ? 'X' : '.'
        end.join
        spaced_at(start_date, span)
      end
    end

    def next_monday
      date = Time.zone.today
      date += 1.day while date.wday != 1
      date
    end

    def delays_between
      @delays_between ||= Hash.new(0)
    end
  end
end
