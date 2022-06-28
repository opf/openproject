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
    attr_accessor :first_day

    def self.for(representation)
      builder = ChartBuilder.new
      builder.parse(representation)
    end

    def work_packages
      @work_packages ||= {}
    end

    def predecessors_by_follower(follower)
      @predecessors_by_follower ||= Hash.new { |h, k| h[k] = [] }
      @predecessors_by_follower[follower]
    end

    def add_work_package(attributes)
      key = attributes[:subject].to_sym
      work_packages[key] = attributes
    end

    def add_follows_relation(predecessor:, follower:)
      predecessors_by_follower(follower) << predecessor
    end

    # Returns the date for the Monday represented on the chart.
    def monday
      unless defined?(@monday)
        @monday = first_day
        @monday += 1 until @monday.wday == 1
      end
      @monday
    end

    # Returns the date for the Tuesday represented on the chart.
    def tuesday
      monday + 1.day
    end

    # Returns the date for the Wednesday represented on the chart.
    def wednesday
      monday + 2.days
    end

    # Returns the date for the Thursday represented on the chart.
    def thursday
      monday + 3.days
    end

    # Returns the date for the Friday represented on the chart.
    def friday
      monday + 4.days
    end

    # Returns the date for the Saturday represented on the chart.
    def saturday
      monday + 5.days
    end

    # Returns the date for the Sunday represented on the chart.
    def sunday
      monday + 6.days
    end
  end

  # Builds a +Chart+ instance from a visual chart representation.
  #
  # Example:
  #
  #   ChartBuilder.new.parse(<<~CHART)
  #     days       | MTWTFss   |
  #     main       | XX        |
  #     follower   |   XXX     | after main
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
      chart
    end

    private

    def parse_header(header)
      _, week_days = header.split(' | ', 2)
      unless week_days.match?(/mtwtfss/i)
        raise ArgumentError, "First header line of schedule chart must contain MTWTFSS to indicate day names"
      end

      nb_days_from_monday = week_days.index(/m/i)
      chart.first_day = next_monday - nb_days_from_monday.days
    end

    def next_monday
      date = Time.zone.today
      while date.wday != 1
        date += 1.day
      end
      date
    end

    def parse_line(line)
      case line
      when ''
        # noop
      when / \| /
        parse_work_package_line(line)
      else
        raise "unable to parse line #{line.inspect}"
      end
    end

    def parse_work_package_line(line)
      name, timespan, modifiers = line.split(' | ', 3)
      name.strip!
      attributes = { subject: name }
      attributes.update(parse_timespan(timespan))
      chart.add_work_package(attributes)

      modifiers.to_s.split(',').map(&:strip).each do |modifier|
        parse_modifier(name, modifier)
      end
    end

    def parse_modifier(name, modifier)
      case modifier
      when /^after (\w+)/
        predecessor = $1.to_sym
        if !chart.work_packages.has_key?(predecessor)
          raise "unable to find work package #{predecessor.inspect} in modifier #{modifier.inspect} for line #{name.inspect}"
        end

        chart.add_follows_relation(predecessor: $1.to_sym, follower: name.to_sym)
      else
        raise "unable to parse modifier #{modifier.inspect} for line #{name.inspect}"
      end
    end

    def parse_timespan(timespan)
      start_pos = timespan.index('[') || timespan.index('X')
      due_pos = timespan.rindex(']') || timespan.rindex('X')
      {
        start_date: start_pos && (chart.first_day + start_pos),
        due_date: due_pos && (chart.first_day + due_pos)
      }
    end

    def parse_follows_relation_line(line)
      to, from = line.split(' -> ', 2).map(&:strip).map(&:to_sym)
      [to, from].each do |name|
        next if chart.work_packages.has_key?(name)

        raise "unable to find work package #{name.inspect} in relation #{line.inspect}"
      end

      { from:, to:, relation_type: Relation::TYPE_FOLLOWS }
    end
  end

  module LetSchedule
    # Declare work packages and relations from a visual chart representation.
    #
    # For instance:
    #
    #   let_schedule(<<~CHART)
    #     days       | MTWTFss   |
    #     main       | XX        |
    #     follower   |   XXX     | after main
    #     start_only |  [        |
    #     due_only   |    ]      |
    #   CHART
    #
    # is equivalent to:
    #
    #   let!(:main) do
    #     create(:work_package, subject: 'main', start_date: next_monday, due_date: next_monday + 1.day)
    #   end
    #   let!(:follower) do
    #     create(:work_package, subject: 'follower', start_date: next_monday + 2.days, due_date: next_monday + 4.days) }
    #   end
    #   let!(:relation_follower_follows_main) do
    #     create(:follows_relation, from: follower, to: main) }
    #   end
    #   let!(:start_only) do
    #     create(:work_package, subject: 'start_only', start_date: next_monday + 1.day) }
    #   end
    #   let!(:due_only) do
    #     create(:work_package, subject: 'due_only', due_date: next_monday + 3.days) }
    #   end
    def let_schedule(chart, **extra_attributes)
      chart = Chart.for(chart)
      let(:schedule_chart) { chart }
      chart.work_packages.each do |name, attributes|
        let!(name) do
          create(:work_package, **attributes.reverse_merge(extra_attributes))
        end
        chart.predecessors_by_follower(name).each do |predecessor|
          relation_alias = "relation_#{name}_follows_#{predecessor}"
          let!(relation_alias) { create(:follows_relation, from: send(name), to: send(predecessor)) }
        end
      end
    end
  end

  module ExampleMethods
    # Update the given work packages according to the given chart representation.
    # Work packages are changed without being saved.
    #
    # For instance:
    #
    #   before do
    #     change_schedule([main], <<~CHART)
    #       days     | MTWTFss   |
    #       main     | XX        |
    #     CHART
    #   end
    #
    # is equivalent to:
    #
    #   before do
    #     main.start_date = monday
    #     main.due_date = tuesday
    #   end
    def update_schedule(work_packages, chart)
      change_schedule(work_packages, chart)
      work_packages.each(&:save!)
    end

    # Change the given work packages according to the given chart representation.
    # Work packages are changed without being saved.
    #
    # For instance:
    #
    #   before do
    #     change_schedule([main], <<~CHART)
    #       days     | MTWTFss   |
    #       main     | XX        |
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
      by_id = work_packages.index_by(&:subject)
      chart = Chart.for(chart)
      chart.work_packages.each do |name, attributes|
        raise ArgumentError, "unable to find WorkPackage :#{name}" unless respond_to?(name)

        work_package = send(name)
        work_package = by_id[work_package.id] if by_id.has_key?(work_package.id)
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
    #       days     | MTWTFss   |
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
      chart.work_packages.each do |name, attributes|
        raise ArgumentError, "unable to find WorkPackage :#{name}" unless respond_to?(name)

        work_package = send(name)
        work_package = by_id[work_package.id] if by_id.has_key?(work_package.id)
        expect(work_package).to have_attributes(attributes.slice(:subject, :start_date, :due_date))
      end
    end
  end
end

RSpec.configure do |config|
  config.extend ScheduleHelpers::LetSchedule
  config.include ScheduleHelpers::ExampleMethods
end
