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
require_relative "../spec_helper"

RSpec.describe MeetingSeriesMailer do
  shared_let(:role) { create(:project_role, permissions: [:view_meetings]) }
  shared_let(:project) { create(:project, name: "My project") }
  shared_let(:author) do
    create(:user,
           member_with_roles: { project => role },
           preferences: { time_zone: "Europe/Berlin" })
  end
  shared_let(:recipient) { create(:user, member_with_roles: { project => role }) }

  let(:series) do
    create(:recurring_meeting,
           title: "Recurring Standup",
           project: project,
           author: author)
  end
  let(:i18n) do
    Class.new do
      include Redmine::I18n

      public :format_date, :format_time
    end
  end

  let(:tokyo_offset) { "UTC#{ActiveSupport::TimeZone['Asia/Tokyo'].now.formatted_offset}" }
  let(:berlin_offset) { "UTC#{ActiveSupport::TimeZone['Europe/Berlin'].now.formatted_offset}" }

  before do
    User.current = author
  end

  describe "template_completed" do
    let(:mail) { described_class.invited(series, recipient, author) }

    it "renders the headers" do
      expect(mail.subject).to include(series.project.name)
      expect(mail.subject).to include(series.title)
      expect(mail.to).to contain_exactly(recipient.mail)
      expect(mail.from).to eq([ApplicationMailer.reply_to_address])
    end

    it "renders the text body" do
      User.execute_as(recipient) do
        check_series_mail_content(mail.text_part.body)
      end
    end

    it "renders the html body" do
      User.execute_as(recipient) do
        check_series_mail_content(mail.html_part.body)
      end
    end

    it "attaches an iCalendar file" do
      expect(mail.attachments["meeting.ics"]).to be_present
    end
  end

  describe "updated" do
    let(:changes) { { old_schedule: "some old schedule", old_location: "some old location" } }
    let(:mail) { described_class.updated(series, recipient, author, changes:) }

    it "renders the headers" do
      expect(mail.subject).to include(series.project.name)
      expect(mail.subject).to include(series.title)
      expect(mail.to).to contain_exactly(recipient.mail)
      expect(mail.from).to eq([ApplicationMailer.reply_to_address])
    end

    it "renders the text body" do
      User.execute_as(recipient) do
        check_series_mail_content(mail.text_part.body)
        expect(mail.text_part.body).to include("has been updated")
        expect(mail.text_part.body).to include("some old schedule")
        expect(mail.text_part.body).to include("some old location")
        expect(mail.text_part.body).to include(series.full_schedule_in_words)
        expect(mail.text_part.body).to include(series.location)
      end
    end

    it "renders the html body" do
      User.execute_as(recipient) do
        check_series_mail_content(mail.html_part.body)
        expect(mail.html_part.body).to include("has been updated")
        expect(mail.html_part.body).to include("some old schedule")
        expect(mail.text_part.body).to include("some old location")
        expect(mail.html_part.body).to include(series.full_schedule_in_words)
        expect(mail.text_part.body).to include(series.location)
      end
    end

    it "attaches an iCalendar file" do
      expect(mail.attachments["meeting.ics"]).to be_present
    end
  end

  describe "icalendar attachment" do
    let(:mail) { described_class.invited(series, recipient, author) }
    let(:ical) { mail.parts.detect { |x| !x.multipart? } }
    let(:parsed) { Icalendar::Event.parse(ical.body.raw_source) }
    let(:entry) { parsed.first }

    it "renders the calendar entry" do
      expect(parsed).to be_a Array
      expect(parsed.length).to eq 1

      expect(entry.summary).to eq "Recurring Standup"
      expect(entry.description).to eq "Link to meeting series: http://#{Setting.host_name}/recurring_meetings/#{series.id}"
      expect(entry.location).to eq(series.template&.location.presence)
    end

    context "with an instantiated occurrence" do
      let!(:template_participant) do
        create(:meeting_participant, :invitee, meeting: series.template, user: recipient)
      end
      let!(:occurrence) do
        create(:recurring_meeting_occurrence,
               recurring_meeting: series,
               start_time: series.start_time,
               recurrence_start_time: series.start_time)
      end
      let(:calendar) { Icalendar::Calendar.parse(mail.attachments["meeting.ics"].body.decoded).first }
      let(:master_event) { calendar.events.find { |event| event.recurrence_id.blank? } }
      let(:occurrence_event) { calendar.events.find { |event| event.recurrence_id.present? } }

      it "renders the series master and occurrence override" do
        expect(calendar.events.length).to eq(2)

        expect(master_event.uid).to eq(series.uid)
        expect(master_event.rrule).not_to be_empty

        expect(occurrence_event.uid).to eq(series.uid)
        expect(occurrence_event.recurrence_id).to eq(occurrence.recurrence_start_time)
        expect(occurrence_event.description.to_s)
          .to include("Link to meeting occurrence: http://#{Setting.host_name}/meetings/#{occurrence.id}")
      end
    end
  end

  context "with a recipient with another time zone" do
    let!(:preference) { recipient.pref.update(time_zone: "Asia/Tokyo") }
    let(:mail) { described_class.invited(series, recipient, author) }

    it "renders the mail with the correct locale" do
      expect(mail.text_part.body).to include(tokyo_offset)
      expect(mail.html_part.body).to include(tokyo_offset)

      expect(mail.to).to contain_exactly(recipient.mail)
    end
  end

  describe "updated with participant changes" do
    let(:changes) { { old_schedule: "some old schedule", old_location: "some old location" } }
    let(:added_names) { ["Added Person"] }
    let(:removed_names) { ["Removed Person"] }
    let(:mail) do
      described_class.updated(series, recipient, author,
                              changes:,
                              added_participants: added_names,
                              removed_participants: removed_names)
    end

    it "renders added participants bold in the html body" do
      User.execute_as(recipient) do
        expect(mail.html_part.body).to include(added_names.first)
      end
    end

    it "renders removed participants with strikethrough in the html body" do
      User.execute_as(recipient) do
        expect(mail.html_part.body).to include("<s>#{removed_names.first}</s>")
      end
    end

    it "renders added and removed participants in the text body" do
      User.execute_as(recipient) do
        expect(mail.text_part.body).to include(added_names.first)
        expect(mail.text_part.body).to include(removed_names.first)
      end
    end
  end

  def check_series_mail_content(body)
    expect(body).to include(series.project.name)
    expect(body).to include(series.title)
    expect(body).to include(series.full_schedule_in_words)
    expect(body).to include(i18n.formatted_time_zone_offset)
  end
end
