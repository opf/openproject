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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe RecurringMeetings::InitOccurrenceService, "permissions", type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:author) do
    create(:user, member_with_permissions: { project => %i[view_meetings create_meetings edit_meetings] })
  end
  shared_let(:series, refind: true) do
    create(:recurring_meeting,
           project:,
           author:,
           start_time: Time.zone.tomorrow + 10.hours,
           frequency: "daily",
           interval: 1,
           end_after: "specific_date",
           end_date: 1.month.from_now)
  end

  let(:start_time) { series.start_time + 3.days }
  let(:viewer) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  let(:service) { described_class.new(recurring_meeting: series, user: viewer) }
  let(:service_result) { service.call(start_time:) }

  context "when initializing a new occurrence slot" do
    it "is not allowed for a view-only user" do
      expect(service_result).not_to be_success
      expect(service_result.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end

  context "when restoring a cancelled occurrence for the slot" do
    let!(:cancelled_occurrence) do
      create(:recurring_meeting_occurrence, :cancelled, recurring_meeting: series, start_time:)
    end

    it "is not allowed for a view-only user" do
      expect(service_result).not_to be_success
      expect(service_result.errors.symbols_for(:base)).to include(:error_unauthorized)
    end

    it "does not change the occurrence state" do
      service_result
      expect(cancelled_occurrence.reload).to be_cancelled
    end

    context "with create_meetings permission" do
      let(:creator) { create(:user, member_with_permissions: { project => %i[view_meetings create_meetings] }) }
      let(:service) { described_class.new(recurring_meeting: series, user: creator) }

      it "restores the cancelled occurrence" do
        expect(service_result).to be_success
        expect(service_result.result).to eq(cancelled_occurrence)
        expect(cancelled_occurrence.reload).to be_open
      end
    end
  end
end
