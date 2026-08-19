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

RSpec.describe AllMeetings::HandleICalResponseService, type: :model do
  let(:user) { create(:user) }
  let(:role) { create(:project_role, permissions: %i[view_meetings]) }
  let(:project) { create(:project, enabled_module_names: %w[meetings], members: { user => role }) }
  let(:service) { described_class.new(user: user) }

  let(:participant_email) { user.mail }
  let(:attendee_string) do
    "ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=#{partstat};CN=#{user.name}:mailto:#{participant_email}"
  end

  let(:ical_method) { "REPLY" }
  let(:additional_ical_properties) { "" }
  let(:ical_string) do
    <<~ICAL
      BEGIN:VCALENDAR
      PRODID:-//OpenProject//Test Meeting Responder 1.0//EN
      VERSION:2.0
      CALSCALE:GREGORIAN
      METHOD:#{ical_method}
      BEGIN:VEVENT
      DTSTART:#{meeting.start_time.utc.strftime('%Y%m%dT%H%M%SZ')}
      DTEND:#{meeting.end_time.utc.strftime('%Y%m%dT%H%M%SZ')}
      DTSTAMP:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
      ORGANIZER;CN=OpenProject:mailto:meetingresponse@example.com
      UID:#{uid}
      #{attendee_string}
      CREATED:#{meeting.created_at.utc.strftime('%Y%m%dT%H%M%SZ')}
      LAST-MODIFIED:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
      SEQUENCE:0
      STATUS:CONFIRMED
      SUMMARY:#{meeting.title}
      TRANSP:OPAQUE
      #{additional_ical_properties}
      END:VEVENT
      END:VCALENDAR
    ICAL
  end

  subject { service.call(ical_string: ical_string) }

  context "when the iCal string is malformed" do
    let(:ical_string) { "" }

    it "returns an error" do
      expect(subject).to be_failure
      expect(subject.message).to eq(I18n.t("meeting.ical_response.update_failed"))
      expect(subject.errors[:base]).to include("No events found in the provided iCal data")
    end
  end

  context "with a regular meeting" do
    let(:meeting) do
      create(:meeting, project: project) do |meeting|
        meeting.participants << create(:meeting_participant, meeting: meeting, user: user, invited: true)
      end
    end

    let(:uid) { meeting.uid }

    context "when accepting the invitation" do
      let(:partstat) { "ACCEPTED" }

      it "updates the participant's status" do
        expect { subject }.to change {
          meeting.participants.find_by(user: user).participation_status
        }.from("needs_action").to("accepted")

        expect(subject).to be_success
      end

      context "when the attendee email has different casing" do
        let(:participant_email) { user.mail.upcase }

        it "still updates the participant's status" do
          expect { subject }.to change {
            meeting.participants.find_by(user: user).participation_status
          }.from("needs_action").to("accepted")

          expect(subject).to be_success
        end
      end
    end

    context "when declining the invitation" do
      let(:partstat) { "DECLINED" }

      it "updates the participant's status" do
        expect { subject }.to change {
          meeting.participants.find_by(user: user).participation_status
        }.from("needs_action").to("declined")
        expect(subject).to be_success
      end
    end

    context "when tentatively accepting the invitation" do
      let(:partstat) { "TENTATIVE" }

      it "updates the participant's status" do
        expect { subject }.to change {
          meeting.participants.find_by(user: user).participation_status
        }.from("needs_action").to("tentative")
        expect(subject).to be_success
      end
    end

    context "when delegating the invitation" do
      let(:partstat) { "DELEGATED" }

      it "returns an error" do
        expect { subject }.not_to change {
          meeting.participants.find_by(user: user).participation_status
        }

        expect(subject).to be_failure
        expect(subject.errors[:base]).to include("'delegated' is not a valid participation_status")
      end
    end

    context "when sending an unknown participation status" do
      let(:partstat) { "x-name" } # experimental/non-standard value

      it "returns an error" do
        expect { subject }.not_to change {
          meeting.participants.find_by(user: user).participation_status
        }

        expect(subject).to be_failure
        expect(subject.errors[:base]).to include("'x-name' is not a valid participation_status")
      end
    end

    context "when the meeting is not found" do
      let(:uid) { "non-existing-uid" }
      let(:partstat) { "ACCEPTED" }

      it "returns an error" do
        expect(subject).to be_failure
        expect(subject.errors[uid]).to include(I18n.t("meeting.ical_response.meeting_not_found"))
      end
    end

    context "when the user is not a participant" do
      let(:other_user) { create(:user) }
      let(:uid) { meeting.uid }
      let(:partstat) { "ACCEPTED" }
      let(:participant_email) { other_user.mail }

      it "warns on the console" do
        allow(Rails.logger).to receive(:warn)
        expect(subject).to be_success
        expect(Rails.logger).to have_received(:warn).with(
          "[iCal Meeting Response] No attendee found for user #{user.mail} in event #{meeting.uid}"
        )
      end
    end

    context "when the iCal method is not REPLY" do
      let(:ical_method) { "COUNTER" }
      let(:partstat) { "ACCEPTED" }

      it "returns an error" do
        expect(subject).to be_failure
        expect(subject.message).to eq(I18n.t("meeting.ical_response.update_failed"))
        expect(subject.errors[:base]).to include("Invalid METHOD in iCal data")
      end
    end

    context "when responding with a comment as X-RESPONSE-COMMENT in the attendee" do
      let(:partstat) { "ACCEPTED" }
      let(:comment) { "Looking forward to the meeting!" }

      let(:attendee_string) do
        "ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=#{partstat};CN=#{user.name};" \
          "X-RESPONSE-COMMENT=#{comment}:mailto:#{participant_email}"
      end

      it "updates the participant's comment" do
        expect { subject }.to change {
          meeting.participants.find_by(user: user).comment
        }.from(nil).to(comment)
        expect(subject).to be_success
      end
    end

    context "when responding with a comment as top level COMMENT property" do
      let(:partstat) { "ACCEPTED" }
      let(:comment) { "Looking forward to the meeting!" }

      let(:additional_ical_properties) { "COMMENT:#{comment}" }

      it "updates the participant's comment" do
        expect { subject }.to change {
          meeting.participants.find_by(user: user).comment
        }.from(nil).to(comment)
        expect(subject).to be_success
      end
    end
  end

  context "with a recurring meeting" do
    let!(:recurring_meeting) do
      create(:recurring_meeting, project: project) do |recurring_meeting|
        recurring_meeting.template.participants << create(:meeting_participant,
                                                          meeting: recurring_meeting.template,
                                                          user: user,
                                                          invited: true)
      end
    end

    context "when responding to the series" do
      let(:uid) { recurring_meeting.uid }
      let(:meeting) { recurring_meeting.template }

      context "when accepting the invitation" do
        let(:partstat) { "ACCEPTED" }

        it "updates the participant's status on the template" do
          expect { subject }.to change {
            meeting.participants.find_by(user: user).participation_status
          }.from("needs_action").to("accepted")

          expect(subject).to be_success
        end
      end

      context "when there already is an instantiated meeting, but it also still waits for a response" do
        let(:partstat) { "ACCEPTED" }
        let(:recurrence_id) { recurring_meeting.start_time + 7.days }
        let!(:meeting) do
          RecurringMeetings::InitOccurrenceService
            .new(user: User.system, recurring_meeting:)
            .call(start_time: recurrence_id)
            .result
        end

        it "updates the participant status on the recurring meeting and the instantiated meeting" do
          expect { subject }.to change {
            recurring_meeting.template.participants.find_by(user: user).participation_status
          }.from("needs_action").to("accepted").and change {
            meeting.participants.find_by(user: user).participation_status
          }.from("needs_action").to("accepted")

          expect(subject).to be_success
        end
      end
    end

    context "when responding to a single occurrence" do
      let(:uid) { recurring_meeting.uid }
      let(:recurrence_id) { recurring_meeting.start_time + 7.days }
      let!(:meeting) do
        RecurringMeetings::InitOccurrenceService
          .new(user: User.system, recurring_meeting:)
          .call(start_time: recurrence_id)
          .result
      end

      let(:additional_ical_properties) do
        "RECURRENCE-ID:#{recurrence_id.utc.strftime('%Y%m%dT%H%M%SZ')}"
      end

      context "when accepting the invitation" do
        let(:partstat) { "ACCEPTED" }

        it "updates the participant's status on the occurence" do
          expect { subject }.to change {
            meeting.participants.find_by(user: user).participation_status
          }.from("needs_action").to("accepted")

          expect(subject).to be_success
        end
      end

      context "when the user is not a participant" do
        let(:other_user) { create(:user) }
        let(:partstat) { "ACCEPTED" }
        let(:participant_email) { other_user.mail }

        it "warns on the console" do
          allow(Rails.logger).to receive(:warn)
          expect(subject).to be_success
          expect(Rails.logger).to have_received(:warn).with(
            "[iCal Meeting Response] No attendee found for user #{user.mail} " \
            "in event #{recurring_meeting.uid} with recurrence ID #{recurrence_id.utc.strftime('%Y-%m-%dT%H:%M:%S+00:00')}"
          )
        end
      end

      context "when the RECURRENCE-ID uses a TZID-qualified local time (e.g., from Open-Xchange)" do
        let(:partstat) { "ACCEPTED" }
        let(:recurrence_id_in_berlin) { recurrence_id.in_time_zone("Europe/Berlin") }

        let(:ical_string) do
          <<~ICAL
            BEGIN:VCALENDAR
            PRODID:-//Open-Xchange//8.45.77//EN
            VERSION:2.0
            CALSCALE:GREGORIAN
            METHOD:REPLY
            BEGIN:VTIMEZONE
            TZID:Europe/Berlin
            BEGIN:DAYLIGHT
            TZNAME:CEST
            TZOFFSETFROM:+0100
            TZOFFSETTO:+0200
            DTSTART:19700329T020000
            RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
            END:DAYLIGHT
            BEGIN:STANDARD
            TZNAME:CET
            TZOFFSETFROM:+0200
            TZOFFSETTO:+0100
            DTSTART:19701025T030000
            RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
            END:STANDARD
            END:VTIMEZONE
            BEGIN:VEVENT
            DTSTART;TZID=Europe/Berlin:#{recurrence_id_in_berlin.strftime('%Y%m%dT%H%M%S')}
            DTEND;TZID=Europe/Berlin:#{(recurrence_id_in_berlin + 1.hour).strftime('%Y%m%dT%H%M%S')}
            DTSTAMP:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
            ORGANIZER;CN=OpenProject:mailto:meetingresponse@example.com
            UID:#{recurring_meeting.uid}
            RECURRENCE-ID;TZID=Europe/Berlin:#{recurrence_id_in_berlin.strftime('%Y%m%dT%H%M%S')}
            #{attendee_string}
            CREATED:#{meeting.created_at.utc.strftime('%Y%m%dT%H%M%SZ')}
            LAST-MODIFIED:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
            SEQUENCE:0
            STATUS:CONFIRMED
            SUMMARY:#{meeting.title}
            TRANSP:OPAQUE
            END:VEVENT
            END:VCALENDAR
          ICAL
        end

        it "finds the meeting occurrence and updates the participant's status" do
          expect { subject }.to change {
            meeting.participants.find_by(user: user).participation_status
          }.from("needs_action").to("accepted")
          expect(RecurringMeetingInterimResponse.count).to eq(0)
          expect(subject).to be_success
        end

        context "when the recurring meeting occurrence is not yet instantiated" do
          let(:recurrence_id_in_berlin) { (recurring_meeting.start_time + 14.days).in_time_zone("Europe/Berlin") }

          it "creates an interim response with the correct start time" do
            expect { subject }.to change(RecurringMeetingInterimResponse, :count).by(1)

            expect(subject).to be_success

            interim_response = RecurringMeetingInterimResponse.last
            expect(interim_response.user).to eq(user)
            expect(interim_response.recurring_meeting).to eq(recurring_meeting)
            expect(interim_response.start_time).to eq(recurrence_id_in_berlin.utc)
            expect(interim_response.participation_status).to eq("accepted")
          end
        end
      end

      context "when no meeting occurrence is found for the recurrence ID" do
        let(:partstat) { "ACCEPTED" }
        let(:recurrence_date) { (recurring_meeting.start_time + 14.days).change(usec: 0) }

        let(:additional_ical_properties) do
          "RECURRENCE-ID:#{recurrence_date.utc.strftime('%Y%m%dT%H%M%SZ')}"
        end

        it "creates an interim response for the not instantiated meeting" do
          expect { subject }.to change(RecurringMeetingInterimResponse, :count).by(1)

          expect(subject).to be_success

          interim_response = RecurringMeetingInterimResponse.last
          expect(interim_response.user).to eq(user)
          expect(interim_response.recurring_meeting).to eq(recurring_meeting)
          expect(interim_response.start_time).to eq(recurrence_date)
          expect(interim_response.participation_status).to eq("accepted")
        end
      end

      context "when an interim response already for this recurrence (the user has already responded and changes)" do
        let(:partstat) { "DECLINED" }
        let(:recurrence_date) { recurring_meeting.start_time + 21.days }
        let!(:existing_response) do
          RecurringMeetingInterimResponse.create!(
            user: user,
            recurring_meeting: recurring_meeting,
            start_time: recurrence_date,
            participation_status: "accepted"
          )
        end

        let(:additional_ical_properties) do
          "RECURRENCE-ID:#{recurrence_date.utc.strftime('%Y%m%dT%H%M%SZ')}"
        end

        it "updates the existing interim response" do
          expect { subject }.not_to change(RecurringMeetingInterimResponse, :count)

          expect(subject).to be_success

          expect do
            existing_response.reload
          end.to change(existing_response, :participation_status).from("accepted").to("declined")
        end
      end
    end

    context "when responding to the series and the occurence in one mail" do
      let(:recurrence_id) { recurring_meeting.start_time + 7.days }
      let!(:meeting) do
        RecurringMeetings::InitOccurrenceService
          .new(user: User.system, recurring_meeting:)
          .call(start_time: recurrence_id)
          .result
      end

      let(:ical_string) do
        <<~ICAL
          BEGIN:VCALENDAR
          PRODID:-//OpenProject//Test Meeting Responder 1.0//EN
          VERSION:2.0
          CALSCALE:GREGORIAN
          METHOD:REPLY
          BEGIN:VEVENT
          DTSTART:#{recurring_meeting.template.start_time.utc.strftime('%Y%m%dT%H%M%SZ')}
          DTEND:#{recurring_meeting.template.end_time.utc.strftime('%Y%m%dT%H%M%SZ')}
          DTSTAMP:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
          ORGANIZER;CN=OpenProject:mailto:meetingresponse@example.com
          UID:#{recurring_meeting.uid}
          ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=ACCEPTED;CN=#{user.name}:mailto:#{participant_email}
          CREATED:#{recurring_meeting.template.created_at.utc.strftime('%Y%m%dT%H%M%SZ')}
          LAST-MODIFIED:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
          SEQUENCE:0
          STATUS:CONFIRMED
          SUMMARY:#{recurring_meeting.title}
          TRANSP:OPAQUE
          END:VEVENT
          BEGIN:VEVENT
          DTSTART:#{meeting.start_time.utc.strftime('%Y%m%dT%H%M%SZ')}
          DTEND:#{meeting.end_time.utc.strftime('%Y%m%dT%H%M%SZ')}
          DTSTAMP:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
          ORGANIZER;CN=OpenProject:mailto:meetingresponse@example.com
          UID:#{recurring_meeting.uid}
          RECURRENCE-ID:#{recurrence_id.utc.strftime('%Y%m%dT%H%M%SZ')}
          ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=DECLINED;CN=#{user.name}:mailto:#{participant_email}
          COMMENT:Sorry\\, I cannot attend this occurrence.
          CREATED:#{meeting.created_at.utc.strftime('%Y%m%dT%H%M%SZ')}
          LAST-MODIFIED:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
          SEQUENCE:0
          STATUS:CONFIRMED
          SUMMARY:#{meeting.title}
          TRANSP:OPAQUE
          END:VEVENT
          END:VCALENDAR
        ICAL
      end

      it "changes the participant's status on both the template and the occurrence" do
        expect { subject }.to change {
          recurring_meeting.template.participants.find_by(user: user).participation_status
        }.from("needs_action").to("accepted").and change {
          meeting.participants.find_by(user: user).participation_status
        }.from("needs_action").to("declined")

        expect(subject).to be_success

        expect(meeting.participants.find_by(user: user).comment).to eq("Sorry, I cannot attend this occurrence.")
      end
    end

    context "when responding to the occurence, but the series is already part of the response, " \
            "eventhough the user is only added to the occurence" do
      let(:recurrence_id) { recurring_meeting.start_time + 7.days }
      let!(:meeting) do
        RecurringMeetings::InitOccurrenceService
          .new(user: User.system, recurring_meeting:)
          .call(start_time: recurrence_id)
          .result
      end

      let(:ical_string) do
        <<~ICAL
          BEGIN:VCALENDAR
          PRODID:-//OpenProject//Test Meeting Responder 1.0//EN
          VERSION:2.0
          CALSCALE:GREGORIAN
          METHOD:REPLY
          BEGIN:VEVENT
          DTSTART:#{recurring_meeting.template.start_time.utc.strftime('%Y%m%dT%H%M%SZ')}
          DTEND:#{recurring_meeting.template.end_time.utc.strftime('%Y%m%dT%H%M%SZ')}
          DTSTAMP:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
          ORGANIZER;CN=OpenProject:mailto:meetingresponse@example.com
          UID:#{recurring_meeting.uid}
          CREATED:#{recurring_meeting.template.created_at.utc.strftime('%Y%m%dT%H%M%SZ')}
          LAST-MODIFIED:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
          SEQUENCE:0
          STATUS:CONFIRMED
          SUMMARY:#{recurring_meeting.title}
          TRANSP:OPAQUE
          END:VEVENT
          BEGIN:VEVENT
          DTSTART:#{meeting.start_time.utc.strftime('%Y%m%dT%H%M%SZ')}
          DTEND:#{meeting.end_time.utc.strftime('%Y%m%dT%H%M%SZ')}
          DTSTAMP:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
          ORGANIZER;CN=OpenProject:mailto:meetingresponse@example.com
          UID:#{recurring_meeting.uid}
          RECURRENCE-ID:#{recurrence_id.utc.strftime('%Y%m%dT%H%M%SZ')}
          ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=DECLINED;CN=#{user.name}:mailto:#{participant_email}
          COMMENT:Sorry\\, I cannot attend this occurrence.
          CREATED:#{meeting.created_at.utc.strftime('%Y%m%dT%H%M%SZ')}
          LAST-MODIFIED:#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}
          SEQUENCE:0
          STATUS:CONFIRMED
          SUMMARY:#{meeting.title}
          TRANSP:OPAQUE
          END:VEVENT
          END:VCALENDAR
        ICAL
      end

      before do
        # remove user from template participants
        recurring_meeting.template.participants.where(user: user).destroy_all
      end

      it "has correct participation as we intended" do
        expect(recurring_meeting.template.participants.find_by(user: user)).to be_nil
        expect(meeting.participants.find_by(user: user)).not_to be_nil
      end

      it "only changes the participant's status on the occurrence" do
        expect { subject }.to change {
          meeting.participants.find_by(user: user).participation_status
        }.from("needs_action").to("declined")

        expect(subject).to be_success

        expect(meeting.participants.find_by(user: user).comment).to eq("Sorry, I cannot attend this occurrence.")
      end
    end
  end
end
