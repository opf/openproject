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

require "icalendar"
require "spec_helper"

RSpec.describe MeetingNotificationService do
  shared_let(:project) { create(:project) }
  shared_let(:actor) { create(:user) }
  shared_let(:series_participant) { create(:user) }
  shared_let(:occurrence_participant) { create(:user) }

  before do
    User.current = actor
    ActionMailer::Base.deliveries.clear
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

      it "sends a series ICS to template participants and a standalone ICS to occurrence-only participants" do
        perform_enqueued_jobs do
          expect(service_call).to be_success
        end

        expect(ActionMailer::Base.deliveries.count).to eq(2)

        series_mail = delivered_mail_for(series_participant)
        occurrence_mail = delivered_mail_for(occurrence_participant)

        series_calendar = parse_ics_attachment(series_mail)
        series_master_event = series_calendar.events.find { |event| event.recurrence_id.blank? }

        expect(series_master_event).to be_present
        expect(series_master_event.uid).to eq(recurring_meeting.uid)
        expect(series_master_event.rrule).not_to be_empty

        occurrence_calendar = parse_ics_attachment(occurrence_mail)

        expect(occurrence_calendar.events.length).to eq(1)
        expect(occurrence_calendar.events.first.uid).to eq(meeting.uid)
        expect(occurrence_calendar.events.first.recurrence_id).to be_nil
        expect(occurrence_calendar.events.first.rrule).to be_empty
      end
    end
  end

  def delivered_mail_for(user)
    ActionMailer::Base.deliveries.find { |mail| mail.to == [user.mail] }
  end

  def parse_ics_attachment(mail)
    Icalendar::Calendar.parse(mail.attachments["meeting.ics"].body.decoded).first
  end
end
