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

require_relative "../spec_helper"

RSpec.describe MeetingMailer do
  shared_let(:role) { create(:project_role, permissions: [:view_meetings]) }
  shared_let(:project) { create(:project, name: "My project") }
  shared_let(:author) do
    create(:user,
           member_with_roles: { project => role },
           preferences: { time_zone: "Europe/Berlin" })
  end
  shared_let(:watcher1) { create(:user, member_with_roles: { project => role }) }
  shared_let(:watcher2) { create(:user, member_with_roles: { project => role }) }

  let(:meeting) do
    create(:meeting,
           author:,
           project:)
  end
  let(:meeting_agenda) do
    create(:meeting_agenda, meeting:)
  end

  before do
    User.current = author

    meeting.participants.merge([meeting.participants.build(user: watcher1, invited: true, attended: false),
                                meeting.participants.build(user: watcher2, invited: true, attended: false)])
    meeting.save!
  end

  describe "invited" do
    let(:mail) { described_class.invited(meeting, watcher1, author) }
    # this is needed to call module functions from Redmine::I18n
    let(:i18n) do
      Class.new do
        include Redmine::I18n
        public :format_date, :format_time
      end
    end

    it "renders the headers" do
      expect(mail.subject).to include(meeting.project.name)
      expect(mail.subject).to include(meeting.title)
      expect(mail.to).to contain_exactly(watcher1.mail)
      expect(mail.from).to eq([Setting.mail_from])
    end

    it "renders the text body" do
      User.execute_as(watcher1) do
        check_meeting_mail_content mail.text_part.body
      end
    end

    it "renders the html body" do
      User.execute_as(watcher1) do
        check_meeting_mail_content mail.html_part.body
      end
    end

    context "with a recipient with another time zone" do
      let!(:preference) { watcher1.pref.update(time_zone: "Asia/Tokyo") }

      it "renders the mail with the correcet locale" do
        expect(mail.text_part.body).to include("Tokyo")
        expect(mail.text_part.body).to include("GMT+09:00")
        expect(mail.html_part.body).to include("Tokyo")
        expect(mail.html_part.body).to include("GMT+09:00")

        expect(mail.to).to contain_exactly(watcher1.mail)
      end
    end

    context "when the meeting time results in another date" do
      let(:meeting) do
        create(:meeting,
               author:,
               project:,
               start_time: "2021-11-09T23:00:00 +0100".to_datetime.utc)
      end

      describe "it renders november 9th for Berlin zone" do
        let(:mail) { described_class.invited(meeting, author, author) }

        it "renders the mail with the correct locale" do
          expect(mail.html_part.body).to include("11/09/2021 11:00 PM")
          expect(mail.html_part.body).to include("12:00 AM (GMT+01:00) Europe/Berlin")
          expect(mail.text_part.body).to include("11/09/2021 11:00 PM-12:00 AM (GMT+01:00) Europe/Berlin")

          expect(mail.to).to contain_exactly(author.mail)
        end
      end

      describe "it renders november 10th for Tokyo zone" do
        let!(:preference) { watcher1.pref.update(time_zone: "Asia/Tokyo") }
        let(:mail) { described_class.invited(meeting, watcher1, author) }

        it "renders the mail with the correct locale" do
          expect(mail.html_part.body).to include("11/10/2021 07:00 AM")
          expect(mail.html_part.body).to include("08:00 AM (GMT+09:00) Asia/Tokyo")

          expect(mail.text_part.body).to include("11/10/2021 07:00 AM-08:00 AM (GMT+09:00) Asia/Tokyo")

          expect(mail.to).to contain_exactly(watcher1.mail)
        end
      end
    end
  end

  describe "icalendar" do
    let(:meeting) do
      create(:meeting,
             author:,
             project:,
             title: "Important meeting",
             location: "https://example.com/meet/important-meeting",
             start_time: "2021-01-19T10:00:00Z".to_time(:utc),
             duration: 1.0)
    end
    let(:mail) { described_class.icalendar_notification(meeting, author, author) }

    it "renders the headers" do
      expect(mail.subject).to include(meeting.project.name)
      expect(mail.subject).to include(meeting.title)
      expect(mail.to).to contain_exactly(author.mail)
      expect(mail.from).to eq([Setting.mail_from])
    end

    describe "text body" do
      subject(:body) { mail.text_part.body }

      it "renders the text body" do
        expect(body).to include(meeting.project.name)
        expect(body).to include(meeting.title)
        expect(body).to include(meeting.location)
        expect(body).to include("01/19/2021 11:00 AM-12:00 PM (GMT+01:00) Europe/Berlin")
        expect(body).to include(meeting.participants[0].name)
        expect(body).to include(meeting.participants[1].name)
      end
    end

    describe "renders the html body" do
      subject(:body) { mail.html_part.body }

      it "renders the text body" do
        expect(body).to include(meeting.project.name)
        expect(body).to include(meeting.title)
        expect(body).to include(meeting.location)
        expect(body).to include("01/19/2021 11:00 AM")
        expect(body).to include("12:00 PM (GMT+01:00) Europe/Berlin")
        expect(body).to include(meeting.participants[0].name)
        expect(body).to include(meeting.participants[1].name)
      end
    end

    describe "renders the calendar entry" do
      let(:ical) { mail.parts.detect { |x| !x.multipart? } }
      let(:parsed) { Icalendar::Event.parse(ical.body.raw_source) }
      let(:entry) { parsed.first }

      it "renders the calendar entry" do
        expect(parsed).to be_a Array
        expect(parsed.length).to eq 1

        expect(entry.dtstart.utc).to eq meeting.start_time
        expect(entry.dtend.utc).to eq meeting.start_time + 1.hour
        expect(entry.summary).to eq "[My project] Important meeting"
        expect(entry.description).to eq "[My project] Meeting: Important meeting"
        expect(entry.location).to eq(meeting.location.presence)
      end

      it "has the correct time matching the timezone" do
        expect(entry.dtstart).to eq "2021-01-19T10:00:00Z".to_time(:utc).in_time_zone("Europe/Berlin")
        expect(entry.dtend).to eq ("2021-01-19T10:00:00Z".to_time(:utc) + 1.hour).in_time_zone("Europe/Berlin")
      end
    end

    context "with a recipient with another time zone" do
      let!(:preference) { watcher1.pref.update(time_zone: "Asia/Tokyo") }
      let(:mail) { described_class.icalendar_notification(meeting, watcher1, author) }

      it "renders the mail with the correct locale" do
        expect(mail.text_part.body).to include("01/19/2021 07:00 PM-08:00 PM (GMT+09:00) Asia/Tokyo")
        expect(mail.html_part.body).to include("01/19/2021 07:00 PM")
        expect(mail.html_part.body).to include("08:00 PM (GMT+09:00) Asia/Tokyo")

        expect(mail.to).to contain_exactly(watcher1.mail)
      end
    end

    context "when the meeting time results in another date" do
      let(:meeting) do
        create(:meeting,
               author:,
               project:,
               start_time: "2021-11-09T23:00:00 +0100".to_datetime.utc)
      end

      describe "it renders november 9th for Berlin zone" do
        let(:mail) { described_class.icalendar_notification(meeting, author, author) }

        it "renders the mail with the correct locale" do
          expect(mail.text_part.body).to include("11/09/2021 11:00 PM-12:00 AM (GMT+01:00) Europe/Berlin")
          expect(mail.html_part.body).to include("11/09/2021 11:00 PM")
          expect(mail.html_part.body).to include("12:00 AM (GMT+01:00) Europe/Berlin")

          expect(mail.to).to contain_exactly(author.mail)
        end
      end

      describe "it renders november 10th for Tokyo zone" do
        let(:mail) { described_class.icalendar_notification(meeting, watcher1, author) }
        let!(:preference) { watcher1.pref.update(time_zone: "Asia/Tokyo") }

        it "renders the mail with the correct locale" do
          expect(mail.text_part.body).to include("11/10/2021 07:00 AM-08:00 AM (GMT+09:00) Asia/Tokyo")
          expect(mail.html_part.body).to include("11/10/2021 07:00 AM-08:00 AM (GMT+09:00) Asia/Tokyo")

          expect(mail.to).to contain_exactly(watcher1.mail)
        end
      end
    end
  end

  def check_meeting_mail_content(body)
    expect(body).to include(meeting.project.name)
    expect(body).to include(meeting.title)
    expect(body).to include(i18n.format_date(meeting.start_date))
    expect(body).to include(i18n.format_time(meeting.start_time, false))
    expect(body).to include(i18n.format_time(meeting.end_time, false))
    expect(body).to include(meeting.participants[0].name)
    expect(body).to include(meeting.participants[1].name)
  end
end
