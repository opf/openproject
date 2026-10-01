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

RSpec.describe Meetings::DeleteService do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:current_user) do
    create(:user, member_with_permissions: { project => %i[view_meetings delete_meetings] })
  end
  shared_let(:series) { create(:recurring_meeting, project:) }

  subject { described_class.new(model: meeting, user: current_user).call }

  describe "#call" do
    context "when the meeting is an occurrence of a series" do
      let(:meeting) do
        create(:recurring_meeting_occurrence, recurring_meeting: series, project:, start_time: 1.day.from_now)
      end

      it "cancels the occurrence instead of destroying it" do
        meeting

        expect { expect(subject).to be_success }.not_to change(Meeting, :count)

        expect(meeting.reload).to be_cancelled
      end

      it "advances the ICS revision of the series" do
        meeting

        expect { expect(subject).to be_success }
          .to change { series.reload.ical_sequence }.by(1)
      end

      context "with an invited participant" do
        let(:recipient) { create(:user, member_with_permissions: { project => %i(view_meetings) }) }

        before do
          series.update_column(:ical_sequence, 7)
          create(:meeting_participant, :invitee, meeting:, user: recipient)
        end

        it "sends the cancellation carrying the new revision, not the one it replaces" do
          expect(subject).to be_success

          calendar = ActionMailer::Base.deliveries.last.all_parts.find { |part| part.mime_type == "text/calendar" }

          expect(series.reload.ical_sequence).to eq 8
          expect(calendar.body.decoded).to include("SEQUENCE:8")
        end
      end
    end

    context "when the meeting does not belong to a series" do
      let(:meeting) { create(:meeting, project:) }

      it "destroys it and leaves the ICS revision of every series alone" do
        meeting

        expect { expect(subject).to be_success }.to change(Meeting, :count).by(-1)

        expect(series.reload.ical_sequence).to eq 0
      end
    end
  end
end
