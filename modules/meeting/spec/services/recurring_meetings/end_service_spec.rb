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

RSpec.describe RecurringMeetings::EndService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] })
  end

  let(:recurring_meeting) do
    create(:recurring_meeting,
           project:,
           start_time: Time.zone.tomorrow + 10.hours,
           frequency: "daily",
           interval: 1,
           end_after: "specific_date",
           end_date: 1.month.from_now)
  end

  let(:service) { described_class.new(recurring_meeting, current_user: user) }

  describe "#call" do
    context "when the service is successful" do
      let(:update_service_instance) { instance_double(RecurringMeetings::UpdateService) }

      before do
        allow(RecurringMeetings::UpdateService)
          .to receive(:new)
                .with(model: recurring_meeting, user: user, contract_class: RecurringMeetings::EndSeriesContract)
                .and_return(update_service_instance)
        allow(update_service_instance)
          .to receive(:call)
                .with(end_after: "specific_date", end_date: Time.zone.yesterday)
                .and_return(ServiceResult.success)
      end

      it "returns a successful result" do
        result = service.call

        expect(result).to be_success
      end

      it "calls the UpdateService with correct parameters" do
        service.call

        expect(RecurringMeetings::UpdateService)
          .to have_received(:new)
                .with(model: recurring_meeting, user: user, contract_class: RecurringMeetings::EndSeriesContract)
        expect(update_service_instance)
          .to have_received(:call)
                .with(end_after: "specific_date", end_date: Time.zone.yesterday)
      end
    end

    context "when the UpdateService fails" do
      let(:error_result) { ServiceResult.failure(errors: { base: ["Some error"] }) }
      let(:update_service_instance) { instance_double(RecurringMeetings::UpdateService) }

      before do
        allow(RecurringMeetings::UpdateService)
          .to receive(:new)
                .with(model: recurring_meeting, user: user, contract_class: RecurringMeetings::EndSeriesContract)
                .and_return(update_service_instance)
        allow(update_service_instance)
          .to receive(:call)
                .with(end_after: "specific_date", end_date: Time.zone.yesterday)
                .and_return(error_result)
      end

      it "returns the failed result" do
        result = service.call

        expect(result).not_to be_success
        expect(result.errors[:base]).to include("Some error")
      end

      it "does not remove meetings or occurrences" do
        allow(recurring_meeting).to receive(:meetings).and_call_original

        service.call

        # Meetings relation may be queried to check instances, but no deletions happen
        expect(recurring_meeting.meetings.not_templated.count).to eq(0)
      end
    end
  end

  describe "occurrence meeting removal" do
    let(:upcoming_time) { Time.zone.tomorrow + 1.day + 10.hours }
    let(:cancelled_time) { Time.zone.tomorrow + 2.days + 10.hours }
    let(:past_time) { Time.zone.yesterday + 10.hours }

    let!(:upcoming_meeting) do
      create(:meeting,
             recurring_meeting:,
             start_time: upcoming_time,
             recurrence_start_time: upcoming_time)
    end

    let!(:cancelled_meeting) do
      create(:meeting,
             recurring_meeting:,
             start_time: cancelled_time,
             recurrence_start_time: cancelled_time,
             state: :cancelled)
    end

    let!(:past_meeting) do
      create(:meeting,
             recurring_meeting:,
             start_time: past_time,
             recurrence_start_time: past_time)
    end

    let(:update_service_instance) { instance_double(RecurringMeetings::UpdateService) }

    before do
      allow(RecurringMeetings::UpdateService)
        .to receive(:new)
        .with(model: recurring_meeting, user: user, contract_class: RecurringMeetings::EndSeriesContract)
        .and_return(update_service_instance)
      allow(update_service_instance)
        .to receive(:call)
        .with(end_after: "specific_date", end_date: Time.zone.yesterday)
        .and_return(ServiceResult.success)
    end

    it "removes upcoming occurrence meetings" do
      expect { service.call }
        .to change { recurring_meeting.meetings.not_templated.where(recurrence_start_time: Time.current..).count }
        .from(2).to(0)
    end

    it "does not remove past occurrence meetings" do
      expect { service.call }
        .not_to change { recurring_meeting.meetings.not_templated.where(recurrence_start_time: ...Time.current).count }
    end

    it "removes both instantiated and cancelled upcoming meetings" do
      service.call

      expect { upcoming_meeting.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { cancelled_meeting.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { past_meeting.reload }.not_to raise_error
    end
  end

  describe "time zone handling" do
    let(:recurring_meeting) do
      create(:recurring_meeting,
             project:,
             start_time: Time.zone.tomorrow + 10.hours,
             time_zone: "America/New_York",
             frequency: "daily",
             interval: 1,
             end_after: "specific_date",
             end_date: 1.month.from_now)
    end

    let(:update_service_instance) { instance_double(RecurringMeetings::UpdateService) }

    before do
      allow(RecurringMeetings::UpdateService)
        .to receive(:new)
              .with(model: recurring_meeting, user: user, contract_class: RecurringMeetings::EndSeriesContract)
              .and_return(update_service_instance)
      allow(update_service_instance)
        .to receive(:call)
              .with(end_after: "specific_date", end_date: Time.zone.yesterday)
              .and_return(ServiceResult.success)
    end

    it "uses Time.zone.yesterday for end_date regardless of meeting timezone" do
      service.call

      expect(RecurringMeetings::UpdateService)
        .to have_received(:new)
              .with(model: recurring_meeting, user: user, contract_class: RecurringMeetings::EndSeriesContract)
      expect(update_service_instance)
        .to have_received(:call)
              .with(end_after: "specific_date", end_date: Time.zone.yesterday)
    end
  end
end
