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

require 'rails_helper'

RSpec.describe WorkPackages::ApplyWorkingDaysChangeJob do
  subject(:job) { described_class }

  shared_let(:user) { create(:user) }
  shared_let(:week_days) { create(:week_days_with_saturday_and_sunday_as_weekend) }

  def set_non_working_week_days(*days)
    days.each do |day|
      wday = %w[xxx monday tuesday wednesday thursday friday saturday sunday].index(day.downcase)
      WeekDay.find_by!(day: wday).update(working: false)
    end
  end

  context 'when a work package includes a date that is now a non-working day' do
    let_schedule(<<~CHART, ignore_non_working_days: false)
      days          | MTWTFSS |
      work_package  | XXXX    |
    CHART

    before do
      set_non_working_week_days('wednesday')
    end

    it 'moves the finish date to the corresponding number of now-excluded days to maintain duration [#31992]' do
      job.perform_now(user_id: user.id)
      expect(WorkPackage.all).to match_schedule(<<~CHART)
        days         | MTWTFSS |
        work_package | XX.XX   |
      CHART
    end
  end

  context 'when a work package includes a date that is now a non-working day, but has working days include weekends' do
    let_schedule(<<~CHART)
      days          | MTWTFSS |
      work_package  | XXXX    | working days include weekends
    CHART

    before do
      set_non_working_week_days('wednesday')
    end

    it 'does not move any dates' do
      job.perform_now(user_id: user.id)
      expect(WorkPackage.all).to match_schedule(<<~CHART)
        days         | MTWTFSS |
        work_package | XXXX    | working days include weekends
      CHART
    end
  end

  context 'when having multiple work packages' do
    let_schedule(<<~CHART, ignore_non_working_days: false)
      days | MTWTFSS |
      wp1  | XX      |
      wp2  |  XX     |
      wp3  |   XX    |
      wp4  |    XX   |
      wp5  | XXXXX   |
    CHART

    before do
      set_non_working_week_days('wednesday')
    end

    it 'updates all impacted work packages' do
      job.perform_now(user_id: user.id)
      expect(WorkPackage.all).to match_schedule(<<~CHART)
        days | MTWTFSS  |
        wp1  | XX       |
        wp2  |  X.X     |
        wp3  |    XX    |
        wp4  |    XX    |
        wp5  | XX.XX..X |
      CHART
    end
  end

  context 'when having multiple work packages following each other' do
    let_schedule(<<~CHART, ignore_non_working_days: false)
      days | MTWTFSS   |
      wp1  |     X..XX | follows wp2
      wp2  |    X      | follows wp3
      wp3  | XXX       |
    CHART

    before do
      set_non_working_week_days('tuesday', 'wednesday', 'friday')
    end

    it 'updates them only once' do
      expect { job.perform_now(user_id: user.id) }
        .to change { WorkPackage.pluck(:lock_version) }
        .from([0, 0, 0])
        .to([1, 1, 1])
      expect(WorkPackage.all).to match_schedule(<<~CHART)
        days | MTWTFSSmtwtfssmtwtfss  |
        wp1  |               X..X...X |
        wp2  |           X            |
        wp3  | X..X...X               |
      CHART
    end
  end

  context 'when a work package was scheduled to start on a date that is now a non-working day' do
    let_schedule(<<~CHART, ignore_non_working_days: false)
      days          | MTWTFSS |
      work_package  |   XX    |
    CHART

    before do
      set_non_working_week_days('wednesday')
    end

    it 'moves the start date to the earliest working day in the future, ' \
       'and the finish date changes by consequence [#31992]' do
      job.perform_now(user_id: user.id)
      expect(WorkPackage.all).to match_schedule(<<~CHART)
        days         | MTWTFSS |
        work_package |    XX   |
      CHART
    end
  end

  context 'when a follower has a predecessor with dates covering a day that is now a non-working day' do
    let_schedule(<<~CHART)
      days        | MTWTFSS |
      predecessor |  XX     | working days work week
      follower    |    XXX  | working days include weekends, follows predecessor
    CHART

    before do
      set_non_working_week_days('wednesday')
    end

    it 'moves the follower start date by consequence of the predecessor dates shift [#31992]' do
      job.perform_now(user_id: user.id)
      expect(WorkPackage.all).to match_schedule(<<~CHART)
        days        | MTWTFSS |
        predecessor |  X.X    | working days work week
        follower    |     XXX | working days include weekends
      CHART
    end
  end
end
