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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe IncomingEmails::Handlers::MeetingResponse do
  let(:email) { instance_double(Mail::Message, attachments: [], subject: "Email subject") }
  let(:user) { build_stubbed(:user) }
  let(:reference) { {} }
  let(:options) { {} }
  let(:plain_text_body) { "Test body" }

  subject(:handler) do
    described_class.new(email, user:, reference:, plain_text_body:, options:)
  end

  describe ".handles?" do
    subject { described_class }

    context "when the mail has a text/calendar attachment" do
      let(:email) do
        Mail.new do
          from "somebody@example.com"
          add_file filename: "reponse.ics", content: "BEGIN:VCALENDAR..."
        end
      end

      it { is_expected.to be_handles(email, reference: {}) }
    end

    context "when the mail has a text/calendar part" do
      let(:email) do
        Mail.new do
          from "somebody@example.com"
          part content_type: "text/plain", body: "This is the body"
          part content_type: "text/calendar", body: "BEGIN:VCALENDAR...", method: "REPLY"
        end
      end

      it { is_expected.to be_handles(email, reference: {}) }
    end
  end

  describe "#process" do
    let(:ical_string) { "BEGIN:VCALENDAR\nEND:VCALENDAR" }
    let(:service_instance) do
      instance_double(AllMeetings::HandleICalResponseService)
    end

    subject(:handler) do
      described_class.new(email, user:, reference:, plain_text_body:, options:)
    end

    before do
      allow(AllMeetings::HandleICalResponseService).to receive(:new).with(user: user).and_return(service_instance)
      allow(service_instance).to receive(:call).with(ical_string: ical_string).and_return(ServiceResult.success)
    end

    context "when the mail has a text/calendar attachment" do
      let(:email) do
        ical_string = self.ical_string # because it is used in the Mail.new block we need a local variable

        Mail.new do
          from "somebody@example.com"
          add_file filename: "reponse.ics", content: ical_string
        end
      end

      it "calls the AllMeetings::HandleICalResponseService with the ical string" do
        result = subject.process
        expect(service_instance).to have_received(:call).with(ical_string: ical_string)
        expect(result).to be_success
      end

      context "when the ical string is empty" do
        let(:ical_string) { "" }

        it "returns a failure ServiceResult" do
          result = subject.process
          expect(result).to be_failure
          expect(result.message).to eq("No iCalendar data found in email from [#{user.mail}]")
        end
      end
    end

    context "when the mail has a text/calendar part" do
      let(:email) do
        ical_string = self.ical_string # because it is used in the Mail.new block we need a local variable

        Mail.new do
          from "somebody@example.com"
          part content_type: "text/plain", body: "This is the body"
          part content_type: "text/calendar", body: ical_string, method: "REPLY"
        end
      end

      it "calls the AllMeetings::HandleICalResponseService with the ical string" do
        result = subject.process
        expect(service_instance).to have_received(:call).with(ical_string: ical_string)
        expect(result).to be_success
      end

      context "when the ical string is empty" do
        let(:ical_string) { "" }

        it "returns a failure ServiceResult" do
          result = subject.process
          expect(result).to be_failure
          expect(result.message).to eq("No iCalendar data found in email from [#{user.mail}]")
        end
      end
    end
  end
end
