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

RSpec.describe ScheduleHelpers::Chart do
  let(:fake_today) { Date.new(2022, 6, 16) } # Thursday 16 June 2022
  let(:monday) { Date.new(2022, 6, 20) } # Monday 20 June
  let(:tuesday) { Date.new(2022, 6, 21) }
  let(:wednesday) { Date.new(2022, 6, 22) }
  let(:thursday) { Date.new(2022, 6, 23) }
  let(:friday) { Date.new(2022, 6, 24) }
  let(:saturday) { Date.new(2022, 6, 25) }
  let(:sunday) { Date.new(2022, 6, 26) }

  subject(:chart) { described_class.new }

  before do
    travel_to(fake_today)
  end

  describe "#first_day" do
    it "returns the first day represented on the graph, which is next Monday" do
      expect(chart.first_day).to eq(monday)
    end

    it "can be set to an earlier date by setting the origin monday to an earlier date" do
      expect(chart.first_day).to eq(monday)

      # no change when origin is moved forward
      expect { chart.monday = monday + 14.days }
        .not_to change(chart, :first_day)

      # change when origin is moved backward
      expect { chart.monday = monday - 14.days }
        .to change(chart, :first_day).to(monday - 14.days)
    end

    context "with work packages" do
      it "returns the minimum between work packages dates and origin Monday" do
        expect(chart.first_day).to eq(monday)

        chart.add_work_package(subject: "wp1", start_date: tuesday)
        expect(chart.first_day).to eq(monday)

        chart.add_work_package(subject: "wp2", start_date: monday - 3.days)
        expect(chart.first_day).to eq(monday - 3.days)

        chart.add_work_package(subject: "wp3", start_date: sunday)
        expect(chart.first_day).to eq(monday - 3.days)

        chart.add_work_package(subject: "wp4", due_date: monday - 6.days)
        expect(chart.first_day).to eq(monday - 6.days)
      end
    end
  end

  describe "#last_day" do
    it "returns the last day represented on the graph, which is the Sunday following origin Monday" do
      expect(chart.last_day).to eq(sunday)
    end

    it "can be set to an later date by setting the origin Monday to a later date" do
      expect(chart.last_day).to eq(sunday)

      # no change when origin is moved backward
      expect { chart.monday = monday - 14.days }
        .not_to change(chart, :last_day)

      # change when origin is moved forward
      expect { chart.monday = monday + 14.days }
        .to change(chart, :last_day).to(sunday + 14.days)
    end

    context "with work packages" do
      it "returns the maximum between work packages dates and the Sunday following origin Monday" do
        expect(chart.last_day).to eq(sunday)

        chart.add_work_package(subject: "wp1", due_date: tuesday + 7.days)
        expect(chart.last_day).to eq(tuesday + 7.days)

        chart.add_work_package(subject: "wp2", start_date: monday - 3.days)
        expect(chart.last_day).to eq(tuesday + 7.days)

        chart.add_work_package(subject: "wp3", start_date: monday + 20.days)
        expect(chart.last_day).to eq(monday + 20.days)
      end
    end
  end

  describe "#compact_dates" do
    it "makes the chart dates fit with the work packages dates" do
      chart.add_work_package(subject: "wp1", start_date: friday - 21.days, due_date: tuesday - 14.days)
      chart.add_work_package(subject: "wp2", start_date: wednesday - 14.days)
      chart.add_work_package(subject: "wp3", due_date: thursday - 14.days)
      chart.add_work_package(subject: "wp4", due_date: thursday - 14.days)

      expect { chart.compact_dates }
        .to change { [chart.monday, chart.first_day, chart.last_day] }
            .from([monday, friday - 21.days, sunday])
            .to([monday - 14.days, friday - 21.days, sunday - 14.days])
    end

    it "does nothing if there are no work packages" do
      expect { chart.compact_dates }
        .not_to change { [chart.monday, chart.first_day, chart.last_day] }
    end

    it "does nothing if none of the work packages have any dates" do
      chart.add_work_package(subject: "wp1")
      chart.add_work_package(subject: "wp2")
      chart.add_work_package(subject: "wp3")

      expect { chart.compact_dates }
        .not_to change { [chart.monday, chart.first_day, chart.last_day] }
    end
  end

  describe "#set_duration" do
    it "sets the duration for a work package" do
      chart.add_work_package(subject: "wp")
      chart.set_duration("wp", 3)
      expect(chart.work_package_attributes("wp")).to include(duration: 3)
    end

    it "must set the duration to a positive integer" do
      chart.add_work_package(subject: "wp")
      expect { chart.set_duration("wp", 0) }
        .to raise_error(ArgumentError, "unable to set duration for wp: duration must be a positive integer (got 0)")

      expect { chart.set_duration("wp", -5) }
        .to raise_error(ArgumentError, "unable to set duration for wp: duration must be a positive integer (got -5)")

      expect { chart.set_duration("wp", "hello") }
        .to raise_error(ArgumentError, 'unable to set duration for wp: duration must be a positive integer (got "hello")')

      expect { chart.set_duration("wp", "42") }
        .to raise_error(ArgumentError, 'unable to set duration for wp: duration must be a positive integer (got "42")')
    end

    it "cannot set the duration if the work package has dates" do
      chart.add_work_package(subject: "wp_start", start_date: monday)
      expect { chart.set_duration("wp_start", 3) }
        .to raise_error(ArgumentError, "unable to set duration for wp_start: start_date is set")

      chart.add_work_package(subject: "wp_due", due_date: monday)
      expect { chart.set_duration("wp_due", 3) }
        .to raise_error(ArgumentError, "unable to set duration for wp_due: due_date is set")

      chart.add_work_package(subject: "wp_both", start_date: monday, due_date: monday)
      expect { chart.set_duration("wp_both", 3) }
        .to raise_error(ArgumentError, "unable to set duration for wp_both: start_date and due_date is set")
    end
  end

  describe "#to_s" do
    shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }

    context "with a chart built from ascii representation" do
      let(:chart) do
        ScheduleHelpers::ChartBuilder.new.parse(<<~CHART)
          days       |    MTWTFSS  |
          main       | X..X        |
          other      |      XXX..X |
          follower   |     XXX     | follows main
          start_only |    [        |
          due_only   |       ]     |
          no_dates   |             |
        CHART
      end

      it "returns the same ascii representation without properties information" do
        expect(chart.to_s).to eq(<<~CHART.chomp)
          days       |    MTWTFSS  |
          main       | X..X        |
          other      |      XXX..X |
          follower   |     XXX     |
          start_only |    [        |
          due_only   |       ]     |
          no_dates   |             |
        CHART
      end
    end

    context "with a chart built from real work packages" do
      let(:work_package1) { build_stubbed(:work_package, subject: "main", start_date: monday, due_date: tuesday) }
      let(:work_package2) do
        build_stubbed(:work_package, subject: "working_days", ignore_non_working_days: false,
                                     start_date: tuesday, due_date: monday + 7.days)
      end
      let(:work_package2bis) do
        build_stubbed(:work_package, subject: "all_days", ignore_non_working_days: true,
                                     start_date: tuesday, due_date: monday + 7.days)
      end
      let(:work_package3) { build_stubbed(:work_package, subject: "start_only", start_date: monday - 3.days) }
      let(:work_package4) { build_stubbed(:work_package, subject: "due_only", due_date: wednesday) }
      let(:work_package5) { build_stubbed(:work_package, subject: "no_dates") }
      let(:chart) do
        ScheduleHelpers::ChartBuilder.new.use_work_packages(
          [
            work_package1,
            work_package2,
            work_package2bis,
            work_package3,
            work_package4,
            work_package5
          ]
        )
      end

      it "returns the same ascii representation without properties information" do
        expect(chart.to_s).to eq(<<~CHART.chomp)
          days         |    MTWTFSS  |
          main         |    XX       |
          working_days |     XXXX..X |
          all_days     |     XXXXXXX |
          start_only   | [           |
          due_only     |      ]      |
          no_dates     |             |
        CHART
      end
    end
  end
end
