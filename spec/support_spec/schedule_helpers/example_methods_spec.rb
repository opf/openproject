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

describe ScheduleHelpers::ExampleMethods do
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

  describe 'expect_schedule' do
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

  describe 'change_schedule' do
    before do
      travel_to(fake_today)
    end

    it 'applies dates changes to a group of work packages from a visual chart representation' do
      main = build_stubbed(:work_package, subject: 'main')
      second = build_stubbed(:work_package, subject: 'second')
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

    it 'does not save changes' do
      main = create(:work_package, subject: 'main')
      expect(main.persisted?).to be(true)
      expect(main.has_changes_to_save?).to be(false)
      change_schedule([main], <<~CHART)
        days   | MTWTFSS |
        main   | XX      |
      CHART
      expect(main.has_changes_to_save?).to be(true)
      expect(main.changes).to eq('start_date' => [nil, monday], 'due_date' => [nil, tuesday])
    end
  end
end
