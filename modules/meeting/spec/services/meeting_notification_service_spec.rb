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

RSpec.describe MeetingNotificationService do
  shared_let(:project) { create(:project) }
  shared_let(:actor) { create(:user) }
  shared_let(:series_participant) { create(:user) }
  shared_let(:occurrence_participant) { create(:user) }

  before do
    User.current = actor
  end

  describe "#call" do
    subject(:service_call) { described_class.new(meeting).call(:invited) }

    context "for a recurring meeting occurrence" do
      let(:recurring_meeting) do
        create(:recurring_meeting,
               project:,
               author: actor,
               start_time: Time.zone.tomorrow + 10.hours)
      end

      let(:meeting) do
        create(:recurring_meeting_occurrence,
               recurring_meeting:,
               start_time: recurring_meeting.start_time,
               recurrence_start_time: recurring_meeting.start_time)
      end

      before do
        recurring_meeting.template.update!(notify: true)

        create(:meeting_participant, :invitee, meeting: recurring_meeting.template, user: series_participant)
        create(:meeting_participant, :invitee, meeting:, user: series_participant)
        create(:meeting_participant, :invitee, meeting:, user: occurrence_participant)
      end

      it "routes template participants to the series mailer and occurrence-only participants to a standalone occurrence" do
        allow(MeetingSeriesMailer).to receive(:invited).and_call_original
        allow(MeetingMailer).to receive(:invited).and_call_original

        expect(service_call).to be_success

        expect(MeetingSeriesMailer).to have_received(:invited)
          .with(recurring_meeting, series_participant, actor)
        expect(MeetingMailer).to have_received(:invited)
          .with(meeting, occurrence_participant, actor, standalone_occurrence: true)
      end
    end
  end
end
