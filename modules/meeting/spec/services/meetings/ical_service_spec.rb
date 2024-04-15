#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

RSpec.describe Meetings::ICalService, type: :model do
  shared_let(:user) { create(:user, firstname: "Bob", lastname: "Barker", mail: "bob@example.com") }
  shared_let(:user2) { create(:user, firstname: "Foo", lastname: "Fooer", mail: "foo@example.com") }
  shared_let(:project) { create(:project, name: "My Project") }

  shared_let(:meeting) do
    create(:meeting,
           author: user,
           project:,
           title: "Important meeting",
           participants: [
             MeetingParticipant.new(user:),
             MeetingParticipant.new(user: user2)
           ],
           location: "https://example.com/meet/important-meeting",
           start_time: Time.zone.parse("2021-01-19T10:00:00Z"),
           duration: 1.0)
  end

  let(:service) { described_class.new(user:, meeting:) }
  let(:result) { service.call.result }

  subject(:entry) { Icalendar::Event.parse(result).first }

  describe "#call" do
    it "returns a success" do
      expect(service.call).to be_success
    end

    context "when exception is raised" do
      subject { service.call }

      before do
        allow(service).to receive(:generate_ical).and_raise StandardError.new("Oh noes")
      end

      it "returns a failure" do
        expect(subject).to be_failure
        expect(subject.message).to eq("Oh noes")
      end
    end

    it "renders the ICS file", :aggregate_failures do
      expect(result).to be_a String

      expect(entry.attendee.map(&:to_s)).to contain_exactly("mailto:foo@example.com", "mailto:bob@example.com")
      expect(entry.dtstart.utc).to eq meeting.start_time
      expect(entry.dtend.utc).to eq meeting.start_time + 1.hour
      expect(entry.summary).to eq "[My Project] Important meeting"
      expect(entry.description).to eq "[My Project] Meeting: Important meeting"
      expect(entry.location).to eq(meeting.location.presence)
      expect(entry.dtstart).to eq Time.zone.parse("2021-01-19T10:00:00Z").in_time_zone("Europe/Berlin")
      expect(entry.dtend).to eq (Time.zone.parse("2021-01-19T10:00:00Z") + 1.hour).in_time_zone("Europe/Berlin")
    end
  end
end
