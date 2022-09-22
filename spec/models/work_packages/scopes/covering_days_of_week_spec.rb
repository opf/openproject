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

RSpec.describe WorkPackages::Scopes::CoveringDaysOfWeek do
  create_shared_association_defaults_for_work_package_factory

  it 'returns work packages having start date or due date being in the given days of week' do
    schedule =
      create_schedule(<<~CHART)
        days         | MTWTFSS |
        covered1     | XX      |
        covered2     |  XX     |
        covered3     |  X      |
        covered4     |  [      |
        covered5     |  ]      |
        not_covered1 | X       |
        not_covered2 |   X     |
        not_covered3 |    XX   |
        not_covered4 |         |
      CHART

    expect(WorkPackage.covering_days_of_week(2))
      .to contain_exactly(
        schedule.work_package("covered1"),
        schedule.work_package("covered2"),
        schedule.work_package("covered3"),
        schedule.work_package("covered4"),
        schedule.work_package("covered5")
      )
  end

  it 'returns work packages having days between start date and due date being in the given days of week' do
    schedule =
      create_schedule(<<~CHART)
        days         | MTWTFSS |
        covered1     | XXXX    |
        covered2     |  XXX    |
        not_covered1 |    XX   |
        not_covered2 | X       |
      CHART

    expect(WorkPackage.covering_days_of_week([2, 3]))
      .to contain_exactly(
        schedule.work_package("covered1"),
        schedule.work_package("covered2")
      )
  end

  context 'if work package ignores non working days' do
    it 'does not returns it' do
      create_schedule(<<~CHART)
        days         | MTWTFSS |
        not_covered  | XXXXXXX | working days include weekends
      CHART

      expect(WorkPackage.covering_days_of_week(3))
        .to eq([])
    end
  end

  it 'does not return work packages having follows relation covering the given days of week' do
    create_schedule(<<~CHART)
      days         | MTWTFSS |
      not_covered1 | X       |
      follower1    |     X   | follows not_covered1
      not_covered2 | X       |
      follower2    |   X     | follows not_covered2
    CHART

    expect(WorkPackage.covering_days_of_week([2, 4]))
      .to eq([])
  end

  it 'does not return work packages having follows relation with delay covering the given days of week' do
    create_schedule(<<~CHART)
      days         | MTWTFSS |
      not_covered1 | X       |
      follower1    |     X   | follows not_covered1 with delay 3
      not_covered2 | X       |
      follower2    |   X     | follows not_covered2 with delay 1
    CHART

    expect(WorkPackage.covering_days_of_week([2, 4]))
      .to eq([])
  end

  it 'accepts a single day of week or an array of days' do
    schedule =
      create_schedule(<<~CHART)
        days          | MTWTFSS |
        covered       |  X      |
        not_covered   | X       |
      CHART

    expect(WorkPackage.covering_days_of_week(2))
      .to eq([schedule.work_package("covered")])
    expect(WorkPackage.covering_days_of_week([2]))
      .to eq([schedule.work_package("covered")])
    expect(WorkPackage.covering_days_of_week([2, 3]))
      .to eq([schedule.work_package("covered")])
  end
end
