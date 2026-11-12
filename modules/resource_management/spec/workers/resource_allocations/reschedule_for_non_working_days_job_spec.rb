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

RSpec.describe ResourceAllocations::RescheduleForNonWorkingDaysJob do
  let(:covered_user) { create(:user) }
  let(:other_covered_user) { create(:user) }
  let(:uncovered_user) { create(:user) }
  let(:canceled_user) { create(:user) }
  let(:schedule_service) { instance_spy(ResourceAllocations::UpdateScheduleService) }

  before do
    create(:resource_allocation, principal: covered_user, start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 9))
    create(:resource_allocation, principal: other_covered_user,
                                 start_date: Date.new(2026, 1, 20), end_date: Date.new(2026, 1, 20))
    create(:resource_allocation, principal: uncovered_user,
                                 start_date: Date.new(2026, 1, 12), end_date: Date.new(2026, 1, 16))
    create(:resource_allocation, principal: canceled_user, state: "canceled",
                                 start_date: Date.new(2026, 1, 5), end_date: Date.new(2026, 1, 9))

    allow(ResourceAllocations::UpdateScheduleService).to receive(:new).and_return(schedule_service)
  end

  it "recomputes each user with an allocated allocation covering a changed date, from the earliest one" do
    described_class.perform_now(dates: [Date.new(2026, 1, 20), Date.new(2026, 1, 7)])

    expect(schedule_service).to have_received(:call).twice
    expect(schedule_service).to have_received(:call).with(users: [covered_user], from: Date.new(2026, 1, 7))
    expect(schedule_service).to have_received(:call).with(users: [other_covered_user], from: Date.new(2026, 1, 7))
  end

  it "receives the dates through the queue" do
    perform_enqueued_jobs do
      described_class.perform_later(dates: [Date.new(2026, 1, 7)])
    end

    expect(schedule_service).to have_received(:call).once.with(users: [covered_user], from: Date.new(2026, 1, 7))
  end
end
