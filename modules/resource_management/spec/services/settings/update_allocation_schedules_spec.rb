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

RSpec.describe Settings::UpdateAllocationSchedules do
  shared_let(:admin) { create(:admin) }

  let!(:kept) { create(:non_working_day, date: Date.new(2026, 1, 1)) }
  let!(:removed) { create(:non_working_day, date: Date.new(2026, 1, 6)) }

  def update_non_working_days(non_working_days)
    Settings::WorkingDaysAndHoursUpdateService
      .new(user: admin)
      .call(working_days: [1, 2, 3, 4, 5], hours_per_day: "8", non_working_days:)
  end

  it "enqueues one reschedule with the added and removed dates" do
    expect do
      update_non_working_days([{ "name" => "Added", "date" => "2026-01-08" },
                               { "id" => kept.id },
                               { "id" => removed.id, "_destroy" => true }])
    end.to have_enqueued_job(ResourceAllocations::RescheduleForNonWorkingDaysJob)
      .exactly(:once)
      .with(dates: contain_exactly(Date.new(2026, 1, 6), Date.new(2026, 1, 8)))
  end

  it "enqueues nothing when the non-working days stay the same" do
    expect { update_non_working_days([{ "id" => kept.id }, { "id" => removed.id }]) }
      .not_to have_enqueued_job(ResourceAllocations::RescheduleForNonWorkingDaysJob)
  end
end
