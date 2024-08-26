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
  # Contains work packages and relations information from a chart
  # representation, and information to render it.
  #
  # The work package information are:
  # * subject
  # * parent
  # * start_date
  # * due_date
  # * duration
  # * ignore_non_working_days
  #
  # The relations information are limited to follows relations and are retrieved
  # with +#predecessors_by_follower+
  #
  # The rendering information are:
  # * chart origin (the monday displayed in the header line)
  # * max and min date
  # * first column size
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
    FIRST_CELL_TEXT = "days".freeze
    WEEK_DAYS_TEXT = "MTWTFSS".freeze

    attr_reader :id_column_size, :first_day, :last_day, :monday

    def self.for(representation)
      builder = ChartBuilder.new
      builder.parse(representation)
    end

    def self.from_work_packages(work_packages)
      ChartBuilder.new.use_work_packages(Array(work_packages))
    end

    def initialize
      self.monday = Date.current.next_occurring(:monday)
      self.id_column_size = FIRST_CELL_TEXT.length
    end

    # duplicates the chart with different representation properties
    def with(order: work_package_names, id_column_size: self.id_column_size, first_day: self.first_day, last_day: self.last_day)
      chart = Chart.new
      order = order.map(&:to_sym)
      extra_names = work_package_names - order
      chart.work_packages_attributes = work_packages_attributes.index_by { _1[:name] }.values_at(*(order + extra_names)).compact
      chart.monday = monday
      chart.id_column_size = id_column_size
      chart.first_day = first_day
      chart.last_day = last_day
      chart.predecessors_by_followers = predecessors_by_followers
      chart.lags_between = lags_between
      chart.parent_by_child = parent_by_child
      chart
    end

    # Sets the origin of the calendar, represented by +M+ on the first line (M as
    # in Monday).
    def monday=(monday)
      raise ArgumentError, "#{monday} is not a Monday" unless monday.wday == 1

      extend_calendar_range(monday, monday + 6.days)
      @monday = monday
    end

    def validate
      work_package_names.each do |follower|
        predecessors_by_follower(follower).each do |predecessor|
          unless work_package_attributes(predecessor)
            raise "unable to find predecessor #{predecessor.inspect} " \
                  "in property \"follows #{predecessor}\" " \
                  "for work package #{follower.inspect}"
          end
        end
      end
    end

    def work_packages_attributes
      @work_packages_attributes ||= []
    end

    def work_package_attributes(name)
      work_packages_attributes.find { |wpa| wpa[:name] == name.to_sym }
    end

    def work_package_names
      work_packages_attributes.pluck(:name)
    end

    def predecessors_by_follower(follower)
      predecessors_by_followers[follower]
    end

    def lag_between(predecessor:, follower:)
      lags_between.fetch([predecessor, follower])
    end

    def add_work_package(attributes)
      attributes[:start_date] ||= WorkPackage.column_defaults["start_date"]
      attributes[:due_date] ||= WorkPackage.column_defaults["due_date"]
      extend_calendar_range(*attributes.values_at(:start_date, :due_date))
      extend_id_column_size(*attributes.values_at(:subject))
      work_packages_attributes << attributes.merge(name: attributes[:subject].to_sym)
    end

    def set_duration(name, duration)
      unless duration.is_a?(Integer) && duration > 0
        raise ArgumentError, "unable to set duration for #{name}: " \
                             "duration must be a positive integer (got #{duration.inspect})"
      end
      attributes = work_package_attributes(name.to_sym)
      dates_attributes = attributes.slice(:start_date, :due_date).compact
      if dates_attributes.any?(&:present?)
        raise ArgumentError, "unable to set duration for #{name}: " \
                             "#{dates_attributes.keys.join(' and ')} is set"
      end
      attributes[:duration] = duration
    end

    def set_ignore_non_working_days(name, ignore_non_working_days)
      attributes = work_package_attributes(name.to_sym)
      attributes[:ignore_non_working_days] = ignore_non_working_days
    end

    def add_follows_relation(predecessor:, follower:, lag:)
      predecessors_by_follower(follower) << predecessor
      lags_between[[predecessor, follower]] = lag
    end

    def add_parent_relation(parent:, child:)
      parent_by_child[child] = parent
    end

    def parent(name)
      parent_by_child[name]
    end

    def to_s
      representer = ChartRepresenter.new(id_column_size:, days_column_size:)
      representer.add_row
      representer.add_cell(FIRST_CELL_TEXT)
      representer.add_cell(spaced_at(monday, WEEK_DAYS_TEXT))
      work_package_names.each do |name|
        representer.add_row
        representer.add_cell(name.to_s)
        representer.add_cell(span(work_package_attributes(name)))
      end
      representer.to_s
    end

    def compact_dates
      @first_day, @last_day = work_packages_attributes.pluck(:start_date, :due_date).flatten.compact.minmax
      @monday = ([@first_day, @last_day, @monday].compact.first - 1).next_occurring(:monday)
      extend_calendar_range(@monday, @monday + 6)
      self
    end

    protected

    attr_writer :work_packages_attributes,
                :id_column_size,
                :first_day,
                :last_day,
                :predecessors_by_followers,
                :lags_between,
                :parent_by_child

    private

    def extend_calendar_range(*dates)
      self.first_day = [@first_day, *dates].compact.min
      self.last_day = [@last_day, *dates].compact.max
    end

    def extend_id_column_size(name)
      self.id_column_size = [id_column_size, name.length].max
    end

    def days_column_size
      (first_day..last_day).count
    end

    def spaced_at(date, text)
      nb_days = date - first_day
      (" " * nb_days) + text
    end

    def span(attributes)
      case attributes
      in { start_date: nil, due_date: nil }
        ""
      in { start_date:, due_date: nil }
        spaced_at(start_date, "[")
      in { start_date: nil, due_date: }
        spaced_at(due_date, "]")
      in { start_date:, due_date: }
        days = days_for(attributes)
        span = (start_date..due_date).map do |date|
          days.working?(date) ? "X" : "."
        end.join
        spaced_at(start_date, span)
      end
    end

    def days_for(attributes)
      if attributes[:ignore_non_working_days]
        WorkPackages::Shared::AllDays.new
      else
        WorkPackages::Shared::WorkingDays.new
      end
    end

    def predecessors_by_followers
      @predecessors_by_followers ||= Hash.new { |h, k| h[k] = [] }
    end

    def lags_between
      @lags_between ||= Hash.new(0)
    end

    def parent_by_child
      @parent_by_child ||= {}
    end
  end
end
