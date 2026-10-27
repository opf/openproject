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
require_relative "../../support/resource_allocations/schedule_helpers"

RSpec.describe ResourceAllocations::RebuildSchedulesJob do
  include ResourceAllocations::ScheduleHelpers

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    create(:user_working_hours, user:, valid_from: Date.new(2025, 1, 1))
    create(:user_working_hours, user: other_user, valid_from: Date.new(2025, 1, 1))
    create(:resource_allocation, principal: user)
    create(:resource_allocation, principal: other_user)
    ResourceAllocations::ScheduledEntry.delete_all
  end

  it "rebuilds the schedule of every principal of an allocated allocation" do
    described_class.perform_now

    expect(stored_schedule(user)).not_to be_empty
    expect(stored_schedule(user)).to match_array(computed_schedule(user))
    expect(stored_schedule(other_user)).to match_array(computed_schedule(other_user))
  end

  it "rebuilds only the schedules of the given users" do
    described_class.perform_now(user_ids: [user.id])

    expect(stored_schedule(user)).to match_array(computed_schedule(user))
    expect(stored_schedule(other_user)).to be_empty
  end
end
