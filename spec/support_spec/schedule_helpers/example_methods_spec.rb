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

RSpec.describe ScheduleHelpers::ExampleMethods do
  create_shared_association_defaults_for_work_package_factory

  describe "create_schedule" do
    let(:monday) { Date.current.next_occurring(:monday) }
    let(:tuesday) { monday + 1.day }

    # rubocop:disable RSpec/ExampleLength
    it "creates work packages from the given chart" do
      schedule = create_schedule(<<~CHART)
        days       | MTWTFSS |
        main       | XX      |
        start_only | [       |
        due_only   |  ]      |
        no_dates   |         |
      CHART

      expect(WorkPackage.count).to eq(4)
      expect(schedule.work_package("main")).to have_attributes(
        subject: "main",
        start_date: monday,
        due_date: tuesday,
        duration: 2
      )
      expect(schedule.work_package("start_only")).to have_attributes(
        subject: "start_only",
        start_date: monday,
        due_date: nil,
        duration: nil
      )
      expect(schedule.work_package("due_only")).to have_attributes(
        subject: "due_only",
        start_date: nil,
        due_date: tuesday,
        duration: nil
      )
      expect(schedule.work_package("no_dates")).to have_attributes(
        subject: "no_dates",
        start_date: nil,
        due_date: nil,
        duration: nil
      )
    end
    # rubocop:enable RSpec/ExampleLength

    it "creates parent/child relations from the given chart" do
      schedule = create_schedule(<<~CHART)
        days      | MTWTFSS |
        main      |         |
        child     |         | child of main
      CHART
      expect(schedule.work_package("main")).to have_attributes(
        children: [schedule.work_package("child")]
      )
      expect(schedule.work_package("child")).to have_attributes(
        parent: schedule.work_package("main")
      )
    end

    it "creates follows relations from the given chart" do
      schedule = create_schedule(<<~CHART)
        days        | MTWTFSS |
        predecessor | XX      |
        follower    |     X   | follows predecessor with lag 2
      CHART
      expect(Relation.count).to eq(1)
      expect(schedule.follows_relation(from: "follower", to: "predecessor")).to be_an_instance_of(Relation)
      expect(schedule.follows_relation(from: "follower", to: "predecessor")).to have_attributes(
        relation_type: "follows",
        lag: 2,
        from: schedule.work_package("follower"),
        to: schedule.work_package("predecessor")
      )
    end
  end

  describe "change_schedule" do
    let(:fake_today) { Date.new(2022, 6, 16) } # Thursday 16 June 2022
    let(:monday) { Date.new(2022, 6, 20) } # Monday 20 June
    let(:tuesday) { Date.new(2022, 6, 21) }
    let(:thursday) { Date.new(2022, 6, 23) }
    let(:friday) { Date.new(2022, 6, 24) }

    before do
      travel_to(fake_today)
    end

    it "applies dates changes to a group of work packages from a visual chart representation" do
      main = build_stubbed(:work_package, subject: "main")
      second = build_stubbed(:work_package, subject: "second")
      change_schedule([main, second], <<~CHART)
        days   | MTWTFSS |
        main   | XX      |
        second |    XX   |
      CHART
      expect(main.start_date).to eq(monday)
      expect(main.due_date).to eq(tuesday)
      expect(second.start_date).to eq(thursday)
      expect(second.due_date).to eq(friday)
    end

    it "does not save changes" do
      main = create(:work_package, subject: "main")
      expect(main.persisted?).to be(true)
      expect(main.has_changes_to_save?).to be(false)
      change_schedule([main], <<~CHART)
        days   | MTWTFSS |
        main   | XX      |
      CHART
      expect(main.has_changes_to_save?).to be(true)
      expect(main.changes).to eq("start_date" => [nil, monday], "due_date" => [nil, tuesday])
    end
  end

  describe "expect_schedule" do
    let_schedule(<<~CHART)
            | MTWTFSS |
      main  | XX      |
      other |   XXX   |
    CHART

    it "checks the work packages properties according to the given work packages and chart representation" do
      expect do
        expect_schedule([main, other], <<~CHART)
                | MTWTFSS |
          main  | XX      |
          other |   XXX   |
        CHART
      end.not_to raise_error
    end

    it "raises an error if start_date is wrong" do
      expect do
        expect_schedule([main], <<~CHART)
                | MTWTFSS |
          main  |  X      |
        CHART
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it "raises an error if due_date is wrong" do
      expect do
        expect_schedule([main], <<~CHART)
                | MTWTFSS |
          main  | XXXXX   |
        CHART
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it "raises an error if a work package name in the chart cannot be found in the given work packages" do
      expect do
        expect_schedule([main], <<~CHART)
                | MTWTFSS |
          main  | XX      |
          other |   XXXX  |
        CHART
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end
end
