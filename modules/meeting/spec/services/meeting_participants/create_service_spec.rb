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

RSpec.describe MeetingParticipants::CreateService do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:meeting) { create(:meeting, project:) }
  shared_let(:current_user) { create(:user, member_with_permissions: { project => %i[view_meetings edit_meetings] }) }
  shared_let(:user_with_meeting_permissions) { create(:user, member_with_permissions: { project => %i[view_meetings] }) }
  shared_let(:user_without_meeting_permissions) { create(:user, member_with_permissions: { project => %i[view_project] }) }
  shared_let(:user_not_in_project) { create(:user) }

  describe "#call" do
    subject { described_class.new(user: current_user).call(meeting:, user_id:, invited: true, attended: false) }

    context "when user has meeting permissions" do
      let(:user_id) { user_with_meeting_permissions.id }

      it "creates a participant successfully" do
        expect { subject }.to change { meeting.participants.count }.by(1)

        expect(subject).to be_success
        expect(subject.result).to be_present
        expect(subject.result.user).to eq(user_with_meeting_permissions)
        expect(subject.result.invited).to be true
        expect(subject.result.attended).to be false
      end

      it "triggers the notification debounce job with since_invited_ids" do
        allow(Meetings::NotificationDebounceJob).to receive(:debounce)
        subject
        expect(Meetings::NotificationDebounceJob).to have_received(:debounce).with(meeting, since_invited_ids: anything)
      end

      context "when notify: false" do
        subject do
          described_class.new(user: current_user, notify: false).call(meeting:, user_id:, invited: true, attended: false)
        end

        it "creates the participant" do
          expect { subject }.to change { meeting.participants.count }.by(1)
        end

        it "does not trigger the notification debounce job" do
          allow(Meetings::NotificationDebounceJob).to receive(:debounce)
          subject
          expect(Meetings::NotificationDebounceJob).not_to have_received(:debounce)
        end
      end

      it "saves a new journal for the meeting",
         with_settings: { journal_aggregation_time_minutes: 0 } do
        expect { subject }.to change { meeting.journals.count }
      end
    end

    context "when user does not have meeting permissions" do
      let(:user_id) { user_without_meeting_permissions.id }

      it "fails to create participant" do
        expect { subject }.not_to change { meeting.participants.count }

        expect(subject).to be_failure
        expect(subject.result).to be_new_record
        expect(subject.errors.full_messages).to include(/is not a valid participant/)
      end
    end

    context "when user is not in project" do
      let(:user_id) { user_not_in_project.id }

      it "fails to create participant" do
        expect { subject }.not_to change { meeting.participants.count }

        expect(subject).to be_failure
        expect(subject.result).to be_new_record
        expect(subject.errors.full_messages).to include(/is not a valid participant/)
      end
    end

    context "when user_id is blank" do
      let(:user_id) { "" }

      it "fails to create participant" do
        expect { subject }.not_to change { meeting.participants.count }

        expect(subject).to be_failure
        expect(subject.result).to be_new_record
        expect(subject.errors.full_messages).to include("User can't be blank.")
      end
    end

    context "when user_id is nil" do
      let(:user_id) { nil }

      it "fails to create participant" do
        expect { subject }.not_to change { meeting.participants.count }

        expect(subject).to be_failure
        expect(subject.result).to be_new_record
        expect(subject.errors.full_messages).to include("User can't be blank.")
      end
    end

    context "when user_id is invalid" do
      let(:user_id) { 999999 }

      it "fails to create participant" do
        expect { subject }.not_to change { meeting.participants.count }

        expect(subject).to be_failure
        expect(subject.result).to be_new_record
        expect(subject.errors.full_messages).to include("User can't be blank.")
      end
    end

    context "when creating with custom attributes" do
      let(:user_id) { user_with_meeting_permissions.id }
      let(:invited) { false }
      let(:attended) { true }

      subject { described_class.new(user: current_user).call(meeting:, user_id:, invited:, attended:) }

      it "creates participant with custom attributes" do
        expect { subject }.to change { meeting.participants.count }.by(1)

        expect(subject).to be_success
        expect(subject.result.invited).to be false
        expect(subject.result.attended).to be true
      end
    end
  end
end
