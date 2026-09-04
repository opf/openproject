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

RSpec.describe Interceptors::RemoveBlockedRecipients do
  let(:to) { ["spam@blocked.com"] }
  let(:cc) { nil }
  let(:bcc) { nil }
  let(:mail) do
    Mail.new({ from: "noreply@example.net", to:, cc:, bcc:, subject: "Notification", body: "Hi" }.compact)
  end

  def intercept!
    described_class.delivering_email(mail)
  end

  context "with a blocked domain configured", with_settings: { blocked_email_domains: ["blocked.com"] } do
    it "removes a blocked recipient" do
      intercept!

      expect(mail.to).to eq []
    end

    it "removes recipients on a subdomain of a blocked domain" do
      mail.to = ["spam@mail.blocked.com"]

      intercept!

      expect(mail.to).to eq []
    end

    context "with allowed recipients alongside blocked ones" do
      let(:to) { ["spam@blocked.com", "customer@example.com"] }

      it "keeps only the allowed ones" do
        intercept!

        expect(mail.to).to eq ["customer@example.com"]
      end
    end

    context "with a blocked recipient in cc and bcc" do
      let(:to) { ["customer@example.com"] }
      let(:cc) { ["spam@blocked.com"] }
      let(:bcc) { ["other@blocked.com"] }

      it "removes them from cc and bcc but keeps to" do
        intercept!

        expect(mail.to).to eq ["customer@example.com"]
        expect(mail.cc).to eq []
        expect(mail.bcc).to eq []
      end
    end

    context "without any blocked recipient" do
      let(:to) { ["customer@example.com"] }

      it "leaves the mail untouched" do
        intercept!

        expect(mail.to).to eq ["customer@example.com"]
      end
    end

    it "leaves the mail deliverable, which DoNotSendMailsWithoutRecipient then cancels" do
      intercept!
      Interceptors::DoNotSendMailsWithoutRecipient.delivering_email(mail)

      expect(mail.perform_deliveries).to be false
    end
  end

  context "without a blocked domain configured" do
    it "leaves the mail untouched" do
      intercept!

      expect(mail.to).to eq ["spam@blocked.com"]
      expect(mail.perform_deliveries).to be true
    end
  end
end
