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

  let(:today) { Date.new(2022, 6, 16) } # Thursday 16 June 2022
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
      chart.first_day = today
    end

    describe '#first_day' do
      it 'returns the first day represented on the graph' do
        expect(chart.first_day).to eq(today)
      end
    end

    %i[monday tuesday wednesday thursday friday saturday sunday].each do |day_name|
      describe "##{day_name}" do
        it "returns the #{day_name} of the week represented on the chart" do
          expected_date = send(day_name)
          expect(chart.send(day_name)).to eq(expected_date)
        end
      end
    end
  end

  describe ScheduleHelpers::ChartBuilder do
    let(:builder) { described_class.new }

    describe 'happy path' do
      let(:next_tuesday) { tuesday + 7.days }

      before do
        travel_to(today)
      end

      it 'reads a chart and convert it into objects with attributes' do
        chart = builder.parse(<<~CHART)
          days       | MTWTFss   |
          main       | XX        |
          other      |    XX..XX |
          follower   |   XXX     | after main
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

    describe 'error handling' do
      it 'raises an error if the relation references a non-existing work package predecessor' do
        expect do
          builder.parse(<<~CHART)
                      | MTWTFss |
            follower  |   XX    | after main
          CHART
        end.to raise_error(RuntimeError, /unable to find work package :main in modifier "after main" for line "follower"/)
      end
    end
  end

  describe 'let_schedule helper' do
    let_schedule(<<~CHART)
      days      | MTWTFss |
      main      | XX      |
      follower  |   XXX   | after main
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
        due_date: schedule_chart.tuesday
      )
      expect(follower).to have_attributes(
        subject: 'follower',
        start_date: schedule_chart.wednesday,
        due_date: schedule_chart.friday
      )
    end

    it 'creates let! calls for follows relations between work packages' do
      expect(follower.follows_relations.count).to eq(1)
      expect(relation_follower_follows_main).to be_an_instance_of(Relation)
    end

    context 'with additional attributes' do
      let_schedule(<<~CHART, done_ratio: 50, schedule_manually: true)
        days      | MTWTFss |
        main      | XX      |
        follower  |   XXX   | after main
      CHART

      it 'applies additional attributes to all created work packages' do
        expect([main, follower]).to all(have_attributes(done_ratio: 50, schedule_manually: true))
      end
    end
  end

  describe 'expect_schedule helper' do
    let_schedule(<<~CHART)
            | MTWTFss |
      main  | XX      |
      other |   XXX   |
    CHART

    it 'checks the work packages properties according to the given work packages and chart representation' do
      expect do
        expect_schedule([main, other], <<~CHART)
                | MTWTFss |
          main  | XX      |
          other |   XXX   |
        CHART
      end.not_to raise_error
    end

    it 'raises an error if start_date is wrong' do
      expect do
        expect_schedule([main], <<~CHART)
                | MTWTFss |
          main  |  X      |
        CHART
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it 'raises an error if due_date is wrong' do
      expect do
        expect_schedule([main], <<~CHART)
                | MTWTFss |
          main  | XXXXX   |
        CHART
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it 'raises an error if no work package exists for a given name' do
      expect do
        expect_schedule([main], <<~CHART)
                  | MTWTFss |
          unknown | XX      |
        CHART
      end.to raise_error(ArgumentError, "unable to find WorkPackage :unknown")
    end

    it 'checks against the given work packages rather than the ones from the let! definitions' do
      expect do
        expect_schedule([], <<~CHART)
                | MTWTFss |
          main  | XX      |
        CHART
      end.not_to raise_error
    end

    it 'uses the work package from the let! definitions if it is not given as parameter' do
      a_modified_instance_of_main = WorkPackage.find(main.id)
      a_modified_instance_of_main.due_date += 2.days
      expect do
        expect_schedule([main], <<~CHART)
                | MTWTFss |
          main  | XX      |
        CHART
      end.not_to raise_error
      expect do
        expect_schedule([a_modified_instance_of_main], <<~CHART)
                | MTWTFss |
          main  | XXXX    |
        CHART
      end.not_to raise_error
      expect do
        expect_schedule([], <<~CHART)
                | MTWTFss |
          main  | XX      |
        CHART
      end.not_to raise_error
    end
  end
end
