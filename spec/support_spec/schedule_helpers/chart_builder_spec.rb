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

require "spec_helper"

RSpec.describe ScheduleHelpers::ChartBuilder do
  let(:fake_today) { Date.new(2022, 6, 16) } # Thursday 16 June 2022
  let(:monday) { Date.new(2022, 6, 20) } # Monday 20 June
  let(:tuesday) { Date.new(2022, 6, 21) }
  let(:wednesday) { Date.new(2022, 6, 22) }
  let(:thursday) { Date.new(2022, 6, 23) }
  let(:friday) { Date.new(2022, 6, 24) }
  let(:saturday) { Date.new(2022, 6, 25) }
  let(:sunday) { Date.new(2022, 6, 26) }

  subject(:builder) { described_class.new }

  describe "happy path" do
    let(:next_tuesday) { tuesday + 7.days }

    before do
      travel_to(fake_today)
    end

    it "reads a chart and convert it into objects with attributes" do
      chart = builder.parse(<<~CHART)
        days       | MTWTFSS   |
        main       | XX        |
        other      |    XX..XX |
        follower   |   XXX     | follows main
        start_only |  [        |
        due_only   |     ]     |
        no_dates   |           |
      CHART
      expect(chart.work_packages_attributes).to eq(
        [
          { name: :main, subject: "main", start_date: monday, due_date: tuesday },
          { name: :other, subject: "other", start_date: thursday, due_date: next_tuesday },
          { name: :follower, subject: "follower", start_date: wednesday, due_date: friday },
          { name: :start_only, subject: "start_only", start_date: tuesday, due_date: nil },
          { name: :due_only, subject: "due_only", start_date: nil, due_date: friday },
          { name: :no_dates, subject: "no_dates", start_date: nil, due_date: nil }
        ]
      )
      expect(chart.predecessors_by_follower(:main)).to eq([])
      expect(chart.predecessors_by_follower(:other)).to eq([])
      expect(chart.predecessors_by_follower(:follower)).to eq([:main])
    end
  end

  describe "origin day" do
    before do
      travel_to(fake_today)
    end

    it "is identified by the M in MTWTFSS and corresponds to next monday" do
      chart = builder.parse(<<~CHART)
        days       | MTWTFSS |
      CHART
      expect(chart.monday).to eq(monday)
      expect(chart.monday).to eq(chart.first_day)
    end

    it "is not identified by mtwtfss which can be used as documentation instead" do
      chart = builder.parse(<<~CHART)
        days | mtwtfssMTWTFSSmtwtfss |
        wp   |   X                   |
      CHART
      expect(chart.monday).to eq(monday)
      expect(chart.first_day).to eq(chart.work_package_attributes(:wp)[:start_date])
    end
  end

  describe "properties" do
    describe "follows <name>" do
      it "adds a follows relation to the named" do
        chart = builder.parse(<<~CHART)
          days       | MTWTFSS   |
          main       |           |
          follower   |           | follows main
        CHART
        expect(chart.predecessors_by_follower(:follower)).to eq([:main])
        expect(chart.lag_between(predecessor: :main, follower: :follower)).to eq(0)
      end

      it "can be declared in any order" do
        chart = builder.parse(<<~CHART)
          days       | MTWTFSS   |
          follower   |           | follows main
          main       |           |
        CHART
        expect(chart.predecessors_by_follower(:follower)).to eq([:main])
        expect(chart.lag_between(predecessor: :main, follower: :follower)).to eq(0)
      end
    end

    describe "follows <name> with lag <n>" do
      it "adds a follows relation to the named with a lag" do
        chart = builder.parse(<<~CHART)
          days       | MTWTFSS   |
          main       |           |
          follower   |           | follows main with lag 3
        CHART
        expect(chart.predecessors_by_follower(:follower)).to eq([:main])
        expect(chart.lag_between(predecessor: :main, follower: :follower)).to eq(3)
      end
    end

    describe "child of <name>" do
      it "sets the parent to the named one" do
        chart = builder.parse(<<~CHART)
          days        | MTWTFSS |
          parent      |         | child of grandparent
          main        |         | child of parent
          grandparent |         |
        CHART
        expect(chart.parent(:grandparent)).to be_nil
        expect(chart.parent(:parent)).to eq(:grandparent)
        expect(chart.parent(:main)).to eq(:parent)
      end
    end

    describe "duration <int>" do
      it "sets the duration of the work package" do
        chart = builder.parse(<<~CHART)
          days        | MTWTFSS |
          main        |         | duration 3
        CHART
        expect(chart.work_package_attributes(:main)).to include(duration: 3)
      end
    end

    describe "working days work week" do
      it "sets ignore_non_working_days to false for the work package" do
        chart = builder.parse(<<~CHART)
          days        | MTWTFSS |
          main        |         | working days work week
        CHART
        expect(chart.work_package_attributes(:main)).to include(ignore_non_working_days: false)
      end
    end

    describe "working days include weekends" do
      it "sets ignore_non_working_days to true for the work package" do
        chart = builder.parse(<<~CHART)
          days        | MTWTFSS |
          main        |         | working days include weekends
        CHART
        expect(chart.work_package_attributes(:main)).to include(ignore_non_working_days: true)
      end
    end
  end

  describe "error handling" do
    it "raises an error if the relation references a non-existing work package predecessor" do
      expect do
        builder.parse(<<~CHART)
                    | MTWTFSS |
          follower  |   XX    | follows main
        CHART
      end.to raise_error(RuntimeError, /unable to find predecessor :main in property "follows main" for work package :follower/)
    end
  end
end
