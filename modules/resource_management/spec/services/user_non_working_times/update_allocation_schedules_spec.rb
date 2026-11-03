# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe UserNonWorkingTimes::UpdateAllocationSchedules do
  shared_let(:admin) { create(:admin) }

  let(:user) { create(:user) }
  let(:start_date) { Date.new(2026, 1, 12) }
  let!(:non_working_time) { create(:user_non_working_time, user:, start_date:, end_date: Date.new(2026, 1, 14)) }
  let(:schedule_service) { instance_spy(ResourceAllocations::UpdateScheduleService) }

  before { allow(ResourceAllocations::UpdateScheduleService).to receive(:new).and_return(schedule_service) }

  describe UserNonWorkingTimes::CreateService do
    it "recomputes the user's schedule from the new start date" do
      described_class
        .new(user: admin)
        .call(user:, start_date: Date.new(2026, 2, 2), end_date: Date.new(2026, 2, 3))

      expect(schedule_service).to have_received(:call).once.with(users: [user], from: Date.new(2026, 2, 2))
    end
  end

  describe UserNonWorkingTimes::UpdateService do
    def update(**params)
      described_class.new(user: admin, model: non_working_time).call(params)
    end

    it "recomputes from the previous start date when it moves later" do
      update(start_date: Date.new(2026, 1, 13))

      expect(schedule_service).to have_received(:call).once.with(users: [user], from: start_date)
    end

    it "recomputes from the new start date when it moves earlier" do
      update(start_date: Date.new(2026, 1, 8))

      expect(schedule_service).to have_received(:call).once.with(users: [user], from: Date.new(2026, 1, 8))
    end

    it "recomputes from the start date when only the end date changes" do
      update(end_date: Date.new(2026, 1, 20))

      expect(schedule_service).to have_received(:call).once.with(users: [user], from: start_date)
    end
  end

  describe UserNonWorkingTimes::DeleteService do
    it "recomputes from the deleted start date" do
      described_class.new(user: admin, model: non_working_time).call

      expect(schedule_service).to have_received(:call).once.with(users: [user], from: start_date)
    end
  end
end
