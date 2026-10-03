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

RSpec.describe Interceptors::LimitDistinctRecipients do
  let(:mail) do
    Mail.new(from: "noreply@example.net", to: ["one@example.com"], subject: "Notification", body: "Hi")
  end

  def intercept!
    described_class.delivering_email(mail)
  end

  context "when the limit is 0" do
    it "leaves the mail untouched" do
      intercept!

      expect(mail.to).to eq ["one@example.com"]
      expect(mail.perform_deliveries).to be true
    end
  end

  context "when a limit is configured", with_settings: { mail_recipient_limits: 1 } do
    it "keeps the first distinct recipient and drops later ones" do
      intercept!
      expect(mail.to).to eq ["one@example.com"]

      second = Mail.new(from: "noreply@example.net", to: ["two@example.com"], subject: "Other", body: "Hi")
      described_class.delivering_email(second)

      expect(second.to).to eq []
    end

    it "leaves a repeated recipient in place" do
      intercept!

      repeat = Mail.new(from: "noreply@example.net", to: ["one@example.com"], subject: "Again", body: "Hi")
      described_class.delivering_email(repeat)

      expect(repeat.to).to eq ["one@example.com"]
    end

    it "cancels delivery once DoNotSendMailsWithoutRecipient runs" do
      intercept!

      second = Mail.new(from: "noreply@example.net", to: ["two@example.com"], subject: "Other", body: "Hi")
      described_class.delivering_email(second)
      Interceptors::DoNotSendMailsWithoutRecipient.delivering_email(second)

      expect(second.perform_deliveries).to be false
    end

    context "when a later recipient is dropped" do
      before do
        intercept!
        allow(OpenProject.logger).to receive(:warn)
        allow(OpenProject::OpenTelemetry).to receive(:add_event)
        allow(OpenProject::Appsignal).to receive(:increment_counter)

        described_class.delivering_email(
          Mail.new(from: "noreply@example.net", to: ["two@example.com"], subject: "Other", body: "Hi")
        )
      end

      it "logs a warning with the drop payload" do
        expect(OpenProject.logger).to have_received(:warn).with(
          a_string_including("Dropped to recipients over mail recipient limit"),
          hash_including(
            reference: :mail_recipient_limit,
            payload: hash_including(field: :to, dropped_count: 1, limit: 1)
          )
        )
      end

      it "emits an OpenTelemetry span event" do
        expect(OpenProject::OpenTelemetry).to have_received(:add_event).with(
          "outbound_mail.recipients_dropped",
          hash_including(
            "openproject.mail.field" => "to",
            "openproject.mail.dropped_count" => 1,
            "openproject.mail.limit" => 1
          )
        )
      end

      it "increments the Appsignal counter" do
        expect(OpenProject::Appsignal).to have_received(:increment_counter).with(
          "outbound_mail.recipients_dropped",
          1,
          field: "to"
        )
      end
    end
  end
end
