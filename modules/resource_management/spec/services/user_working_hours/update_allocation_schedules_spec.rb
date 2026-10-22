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

RSpec.describe UserWorkingHours::UpdateAllocationSchedules do
  shared_let(:admin) { create(:admin) }

  let(:user) { create(:user) }
  let(:valid_from) { Date.current + 10.days }
  let!(:working_hours) { create(:user_working_hours, user:, valid_from:) }
  let(:schedule_service) { instance_spy(ResourceAllocations::UpdateScheduleService) }

  before { allow(ResourceAllocations::UpdateScheduleService).to receive(:new).and_return(schedule_service) }

  describe UserWorkingHours::CreateService do
    it "recomputes the user's schedule from the new valid_from" do
      described_class
        .new(user: admin)
        .call(user:, valid_from: valid_from + 7.days,
              monday_hours: 4, tuesday_hours: 0, wednesday_hours: 0, thursday_hours: 0, friday_hours: 0,
              saturday_hours: 0, sunday_hours: 0, availability_factor: 100)

      expect(schedule_service).to have_received(:call).once.with(users: [user], from: valid_from + 7.days)
    end
  end

  describe UserWorkingHours::UpdateService do
    def update(**params)
      described_class.new(user: admin, model: working_hours).call(params)
    end

    it "recomputes from the previous valid_from when it moves later" do
      update(valid_from: valid_from + 5.days)

      expect(schedule_service).to have_received(:call).once.with(users: [user], from: valid_from)
    end

    it "recomputes from the new valid_from when it moves earlier" do
      update(valid_from: valid_from - 3.days)

      expect(schedule_service).to have_received(:call).once.with(users: [user], from: valid_from - 3.days)
    end

    it "recomputes from the valid_from when the hours change" do
      update(monday_hours: 2)

      expect(schedule_service).to have_received(:call).once.with(users: [user], from: valid_from)
    end
  end

  describe UserWorkingHours::DeleteService do
    it "recomputes from the deleted valid_from" do
      described_class.new(user: admin, model: working_hours).call

      expect(schedule_service).to have_received(:call).once.with(users: [user], from: valid_from)
    end
  end
end
