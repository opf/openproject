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

describe ScheduleHelpers::LetSchedule do
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

  describe 'let_schedule' do
    let_schedule(<<~CHART)
      days      | MTWTFSS |
      main      | XX      |
      follower  |   XXX   | follows main with delay 2
      child     |         | child of main
    CHART

    it 'creates let! call for :schedule_chart which returns the chart' do
      next_monday = (Time.zone.today..(Time.zone.today + 7.days)).find { |d| d.wday == 1 }
      expect(schedule_chart.first_day).to eq(next_monday)
    end

    it 'creates let! calls for each work package' do
      expect([main, follower, child]).to all(be_an_instance_of(WorkPackage))
      expect([main, follower, child]).to all(be_persisted)
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
      expect(child).to have_attributes(
        subject: 'child',
        start_date: nil,
        due_date: nil
      )
    end

    it 'creates let! calls for follows relations between work packages' do
      expect(follower.follows_relations.count).to eq(1)
      expect(relation_follower_follows_main).to be_an_instance_of(Relation)
      expect(relation_follower_follows_main.delay).to eq(2)
    end

    it 'creates parent / child relations' do
      expect(child.parent).to eq(main)
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
end
