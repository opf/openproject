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

require 'spec_helper'

describe ScheduleHelpers do
  include ActiveSupport::Testing::TimeHelpers

  create_shared_association_defaults_for_work_package_factory

  let(:fake_today) { Date.new(2022, 6, 16) } # Thursday 16 June 2022
  let(:monday) { Date.new(2022, 6, 20) } # Monday 20 June
  let(:tuesday) { Date.new(2022, 6, 21) }
  let(:wednesday) { Date.new(2022, 6, 22) }
  let(:thursday) { Date.new(2022, 6, 23) }
  let(:friday) { Date.new(2022, 6, 24) }
  let(:saturday) { Date.new(2022, 6, 25) }
  let(:sunday) { Date.new(2022, 6, 26) }

  describe ScheduleHelpers::Chart do
    let(:chart) { described_class.new }

    before do
      travel_to(fake_today)
    end

    describe '#first_day' do
      context 'without work packages' do
        it 'returns the first day represented on the graph, which is next Monday' do
          expect(chart.first_day).to eq(monday)
        end
      end

      context 'with work packages' do
        it 'returns the minimum between work packages dates and origin Monday' do
          expect(chart.first_day).to eq(monday)

          chart.add_work_package(subject: 'wp1', start_date: tuesday)
          expect(chart.first_day).to eq(monday)

          chart.add_work_package(subject: 'wp2', start_date: monday - 3.days)
          expect(chart.first_day).to eq(monday - 3.days)

          chart.add_work_package(subject: 'wp3', start_date: sunday)
          expect(chart.first_day).to eq(monday - 3.days)

          chart.add_work_package(subject: 'wp4', due_date: monday - 6.days)
          expect(chart.first_day).to eq(monday - 6.days)
        end
      end

      it 'can be set to an earlier date by setting the origin monday to an earlier date' do
        expect(chart.first_day).to eq(monday)

        # no change when origin is moved forward
        expect { chart.monday = monday + 14.days }
          .not_to change(chart, :first_day)

        # change when origin is moved backward
        expect { chart.monday = monday - 14.days }
          .to change(chart, :first_day).to(monday - 14.days)
      end
    end

    describe '#last_day' do
      context 'without work packages' do
        it 'returns the last day represented on the graph, which is the Sunday following origin Monday' do
          expect(chart.last_day).to eq(sunday)
        end
      end

      context 'with work packages' do
        it 'returns the maximum between work packages dates and the Sunday following origin Monday' do
          expect(chart.last_day).to eq(sunday)

          chart.add_work_package(subject: 'wp1', due_date: tuesday + 7.days)
          expect(chart.last_day).to eq(tuesday + 7.days)

          chart.add_work_package(subject: 'wp2', start_date: monday - 3.days)
          expect(chart.last_day).to eq(tuesday + 7.days)

          chart.add_work_package(subject: 'wp3', start_date: monday + 20.days)
          expect(chart.last_day).to eq(monday + 20.days)
        end
      end

      it 'can be set to an later date by setting the origin Monday to a later date' do
        expect(chart.last_day).to eq(sunday)

        # no change when origin is moved backward
        expect { chart.monday = monday - 14.days }
          .not_to change(chart, :last_day)

        # change when origin is moved forward
        expect { chart.monday = monday + 14.days }
          .to change(chart, :last_day).to(sunday + 14.days)
      end
    end

    describe '#to_s' do
      let!(:week_days) { create(:week_days) }

      context 'with a chart built from ascii representation' do
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

        it 'returns the same ascii representation without properties information' do
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

      context 'with a chart built from real work packages' do
        let(:work_package1) { build_stubbed(:work_package, subject: 'main', start_date: monday, due_date: tuesday) }
        let(:work_package2) { build_stubbed(:work_package, subject: 'other', start_date: tuesday, due_date: monday + 7.days) }
        let(:work_package3) { build_stubbed(:work_package, subject: 'start_only', start_date: monday - 3.days) }
        let(:work_package4) { build_stubbed(:work_package, subject: 'due_only', due_date: wednesday) }
        let(:work_package5) { build_stubbed(:work_package, subject: 'no_dates') }
        let(:chart) do
          ScheduleHelpers::ChartBuilder.new.use_work_packages(
            [
              work_package1,
              work_package2,
              work_package3,
              work_package4,
              work_package5
            ]
          )
        end

        it 'returns the same ascii representation without properties information' do
          expect(chart.to_s).to eq(<<~CHART.chomp)
            days       |    MTWTFSS  |
            main       |    XX       |
            other      |     XXXX..X |
            start_only | [           |
            due_only   |      ]      |
            no_dates   |             |
          CHART
        end
      end
    end
  end

  describe ScheduleHelpers::ChartBuilder do
    let(:builder) { described_class.new }

    describe 'happy path' do
      let(:next_tuesday) { tuesday + 7.days }

      before do
        travel_to(fake_today)
      end

      it 'reads a chart and convert it into objects with attributes' do
        chart = builder.parse(<<~CHART)
          days       | MTWTFSS   |
          main       | XX        |
          other      |    XX..XX |
          follower   |   XXX     | follows main
          start_only |  [        |
          due_only   |     ]     |
          no_dates   |           |
        CHART
        expect(chart.work_packages).to eq(
          {
            main: { subject: 'main', start_date: monday, due_date: tuesday },
            other: { subject: 'other', start_date: thursday, due_date: next_tuesday },
            follower: { subject: 'follower', start_date: wednesday, due_date: friday },
            start_only: { subject: 'start_only', start_date: tuesday, due_date: nil },
            due_only: { subject: 'due_only', start_date: nil, due_date: friday },
            no_dates: { subject: 'no_dates', start_date: nil, due_date: nil }
          }
        )
        expect(chart.predecessors_by_follower(:main)).to eq([])
        expect(chart.predecessors_by_follower(:other)).to eq([])
        expect(chart.predecessors_by_follower(:follower)).to eq([:main])
      end
    end

    describe 'origin day' do
      before do
        travel_to(fake_today)
      end

      it 'is identified by the M in MTWTFSS and corresponds to next monday' do
        chart = builder.parse(<<~CHART)
          days       | MTWTFSS |
        CHART
        expect(chart.monday).to eq(monday)
        expect(chart.monday).to eq(chart.first_day)
      end

      it 'is not identified by mtwtfss which can be used as documentation instead' do
        chart = builder.parse(<<~CHART)
          days | mtwtfssMTWTFSSmtwtfss |
          wp   |   X                   |
        CHART
        expect(chart.monday).to eq(monday)
        expect(chart.first_day).to eq(chart.work_packages.dig(:wp, :start_date))
      end
    end

    describe 'properties' do
      describe 'follows <name>' do
        it 'adds a follows relation to the named' do
          chart = builder.parse(<<~CHART)
            days       | MTWTFSS   |
            main       |           |
            follower   |           | follows main
          CHART
          expect(chart.predecessors_by_follower(:follower)).to eq([:main])
          expect(chart.delay_between(predecessor: :main, follower: :follower)).to eq(0)
        end

        it 'can be declared in any order' do
          chart = builder.parse(<<~CHART)
            days       | MTWTFSS   |
            follower   |           | follows main
            main       |           |
          CHART
          expect(chart.predecessors_by_follower(:follower)).to eq([:main])
          expect(chart.delay_between(predecessor: :main, follower: :follower)).to eq(0)
        end
      end

      describe 'follows <name> with delay <n>' do
        it 'adds a follows relation to the named with a delay' do
          chart = builder.parse(<<~CHART)
            days       | MTWTFSS   |
            main       |           |
            follower   |           | follows main with delay 3
          CHART
          expect(chart.predecessors_by_follower(:follower)).to eq([:main])
          expect(chart.delay_between(predecessor: :main, follower: :follower)).to eq(3)
        end
      end
    end

    describe 'error handling' do
      it 'raises an error if the relation references a non-existing work package predecessor' do
        expect do
          builder.parse(<<~CHART)
                      | MTWTFSS |
            follower  |   XX    | follows main
          CHART
        end.to raise_error(RuntimeError, /unable to find predecessor :main in property "follows main" for work package :follower/)
      end
    end
  end

  describe 'let_schedule helper' do
    let_schedule(<<~CHART)
      days      | MTWTFSS |
      main      | XX      |
      follower  |   XXX   | follows main with delay 2
    CHART

    it 'creates let! call for :schedule_chart which returns the chart' do
      next_monday = (Time.zone.today..(Time.zone.today + 7.days)).find { |d| d.wday == 1 }
      expect(schedule_chart.first_day).to eq(next_monday)
    end

    it 'creates let! calls for each work package' do
      expect([main, follower]).to all(be_an_instance_of(WorkPackage))
      expect([main, follower]).to all(be_persisted)
      expect(main).to have_attributes(
        subject: 'main',
        start_date: schedule_chart.monday,
        due_date: schedule_chart.monday + 1.day
      )
      expect(follower).to have_attributes(
        subject: 'follower',
        start_date: schedule_chart.monday + 2.days,
        due_date: schedule_chart.monday + 4.days
      )
    end

    it 'creates let! calls for follows relations between work packages' do
      expect(follower.follows_relations.count).to eq(1)
      expect(relation_follower_follows_main).to be_an_instance_of(Relation)
      expect(relation_follower_follows_main.delay).to eq(2)
    end

    context 'with additional attributes' do
      let_schedule(<<~CHART, done_ratio: 50, schedule_manually: true)
        days      | MTWTFSS |
        main      | XX      |
        follower  |   XXX   | follows main
      CHART

      it 'applies additional attributes to all created work packages' do
        expect([main, follower]).to all(have_attributes(done_ratio: 50, schedule_manually: true))
      end
    end
  end

  describe 'expect_schedule helper' do
    let_schedule(<<~CHART)
            | MTWTFSS |
      main  | XX      |
      other |   XXX   |
    CHART

    it 'checks the work packages properties according to the given work packages and chart representation' do
      expect do
        expect_schedule([main, other], <<~CHART)
                | MTWTFSS |
          main  | XX      |
          other |   XXX   |
        CHART
      end.not_to raise_error
    end

    it 'raises an error if start_date is wrong' do
      expect do
        expect_schedule([main], <<~CHART)
                | MTWTFSS |
          main  |  X      |
        CHART
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it 'raises an error if due_date is wrong' do
      expect do
        expect_schedule([main], <<~CHART)
                | MTWTFSS |
          main  | XXXXX   |
        CHART
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it 'raises an error if no work package exists for a given name' do
      expect do
        expect_schedule([main], <<~CHART)
                  | MTWTFSS |
          unknown | XX      |
        CHART
      end.to raise_error(ArgumentError, "unable to find WorkPackage :unknown")
    end

    it 'checks against the given work packages rather than the ones from the let! definitions' do
      expect do
        expect_schedule([], <<~CHART)
                | MTWTFSS |
          main  | XX      |
        CHART
      end.not_to raise_error
    end

    it 'uses the work package from the let! definitions if it is not given as parameter' do
      a_modified_instance_of_main = WorkPackage.find(main.id)
      a_modified_instance_of_main.due_date += 2.days
      expect do
        expect_schedule([main], <<~CHART)
                | MTWTFSS |
          main  | XX      |
        CHART
      end.not_to raise_error
      expect do
        expect_schedule([a_modified_instance_of_main], <<~CHART)
                | MTWTFSS |
          main  | XXXX    |
        CHART
      end.not_to raise_error
      expect do
        expect_schedule([], <<~CHART)
                | MTWTFSS |
          main  | XX      |
        CHART
      end.not_to raise_error
    end
  end
end
