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

RSpec.describe MeetingParticipants::DeleteService do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:current_user) { create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] }) }
  shared_let(:participant_user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }

  let(:participant) { create(:meeting_participant, meeting:, user: participant_user) }

  describe "#call" do
    subject { described_class.new(user: current_user, model: participant).call }

    context "when user has edit permissions" do
      it "deletes the participant successfully" do
        participant

        expect { subject }.to change { meeting.participants.count }.by(-1)

        expect(subject).to be_success
      end

      it "triggers the notification debounce job with since_invited_ids" do
        participant
        allow(Meetings::NotificationDebounceJob).to receive(:debounce)
        subject
        expect(Meetings::NotificationDebounceJob).to have_received(:debounce).with(meeting, since_invited_ids: anything)
      end

      context "when notify: false" do
        subject { described_class.new(user: current_user, model: participant, notify: false).call }

        it "deletes the participant" do
          participant
          expect { subject }.to change { meeting.participants.count }.by(-1)
        end

        it "does not trigger the notification debounce job" do
          participant
          allow(Meetings::NotificationDebounceJob).to receive(:debounce)
          subject
          expect(Meetings::NotificationDebounceJob).not_to have_received(:debounce)
        end
      end

      it "saves a new journal for the meeting reflecting the participant removal",
         with_settings: { journal_aggregation_time_minutes: 0 } do
        participant
        meeting.touch_and_save_journals # snapshot participant into journal baseline
        expect { subject }.to change { meeting.journals.count }
      end
    end

    context "when user does not have edit permissions" do
      let(:current_user) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }

      it "does not delete the participant" do
        participant

        expect { subject }.not_to change { meeting.participants.count }

        expect(subject).to be_failure
      end
    end
  end
end
