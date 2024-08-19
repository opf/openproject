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
  # Builds a +Chart+ instance from a visual chart representation.
  #
  # Example:
  #
  #   ChartBuilder.new.parse(<<~CHART)
  #     days       | MTWTFSS   |
  #     main       | XX        |
  #     follower   |   XXX     | follows main
  #     start_only |  [        |
  #     due_only   |    ]      |
  #     no_dates   |           |
  #   CHART
  class ChartBuilder
    attr_reader :chart

    def initialize
      @chart = Chart.new
    end

    def parse(representation)
      lines = representation.split("\n")
      header = lines.shift
      parse_header(header)
      lines.each do |line|
        parse_line(line)
      end
      chart.validate
      chart
    end

    def use_work_packages(work_packages)
      work_packages.each do |work_package|
        chart.add_work_package(work_package.slice(:subject, :start_date, :due_date, :ignore_non_working_days))
      end
      chart
    end

    private

    def parse_header(header)
      _, week_days = header.split(" | ", 2)
      unless week_days.include?(Chart::WEEK_DAYS_TEXT)
        raise ArgumentError,
              "First header line of schedule chart must contain #{Chart::WEEK_DAYS_TEXT} to indicate day names and have an origin"
      end

      @nb_days_from_origin_monday = week_days.index(Chart::WEEK_DAYS_TEXT.first)
    end

    def parse_line(line)
      case line
      when ""
        # noop
      when / \| /
        parse_work_package_line(line)
      else
        raise "unable to parse line #{line.inspect}"
      end
    end

    def parse_work_package_line(line)
      name, timespan, properties = line.split(" | ", 3)
      name.strip!
      attributes = { subject: name }
      attributes.update(parse_timespan(timespan))
      chart.add_work_package(attributes)

      properties.to_s.split(",").map(&:strip).each do |property|
        parse_properties(name, property)
      end
    end

    def parse_properties(name, property)
      case property
      when /^follows (\w+)(?: with lag (\d+))?/
        chart.add_follows_relation(
          predecessor: $1.to_sym,
          follower: name.to_sym,
          lag: $2.to_i
        )
      when /^child of (\w+)/
        chart.add_parent_relation(
          parent: $1.to_sym,
          child: name.to_sym
        )
      when /^duration (\d+)/
        chart.set_duration(name, $1.to_i)
      when /^working days work week$/
        chart.set_ignore_non_working_days(name, false)
      when /^working days include weekends$/
        chart.set_ignore_non_working_days(name, true)
      else
        spell_checker = DidYouMean::SpellChecker.new(
          dictionary: [
            "follows :wp",
            "follows :wp with lag :int",
            "child of :wp",
            "duration :int",
            "working days work week",
            "working days include weekends"
          ]
        )
        suggestions = spell_checker.correct(property).map(&:inspect).join(" ")
        did_you_mean = " Did you mean #{suggestions} instead?" if suggestions.present?
        raise "unable to parse property #{property.inspect} for line #{name.inspect}.#{did_you_mean}"
      end
    end

    def parse_timespan(timespan)
      start_pos = timespan.index("[") || timespan.index("X")
      due_pos = timespan.rindex("]") || timespan.rindex("X")
      {
        start_date: start_pos && (chart.monday - @nb_days_from_origin_monday + start_pos),
        due_date: due_pos && (chart.monday - @nb_days_from_origin_monday + due_pos)
      }
    end
  end
end
