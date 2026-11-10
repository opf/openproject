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
require_module_spec_helper

RSpec.describe ITSM::HelpdeskMailer do
  subject(:mail) { described_class.confirmation(email_message, mailbox, "203.0.113.10") }

  let(:work_package) { create(:work_package, subject: "Printer is broken") }
  let(:thread) { create(:itsm_email_thread, work_package:, requester_name: "Jane Doe") }
  let(:email_message) do
    create(:itsm_email_message,
           thread:,
           direction: "outbound",
           status: "queued",
           message_id: "confirmation@example.com",
           from_address: "support@example.com",
           from_name: "Support",
           to_addresses: ["requester@customer.example"],
           cc_addresses: ["colleague@customer.example"],
           subject: "[##{work_package.id}] Printer is broken",
           in_reply_to: "follow-up@customer.example",
           referenced_message_ids: %w[request@customer.example follow-up@customer.example])
  end
  let(:mailbox) { create(:itsm_outgoing_mailbox) }

  it "addresses the requester and the recipients from the mailbox" do
    expect(mail[:from].to_s).to eq("Support <support@example.com>")
    expect(mail).to have_attributes(to: ["requester@customer.example"],
                                    cc: ["colleague@customer.example"],
                                    subject: "[##{work_package.id}] Printer is broken")
  end

  it "replies to the request" do
    expect(mail).to have_attributes(message_id: "confirmation@example.com",
                                    in_reply_to: "follow-up@customer.example",
                                    references: %w[request@customer.example follow-up@customer.example])
    expect(mail.encoded).to include("Message-ID: <confirmation@example.com>")
  end

  it "confirms the request" do
    expect(mail.body.encoded).to include("Hello Jane Doe,",
                                         %(request "Printer is broken" and recorded it as ##{work_package.id}.))
  end

  context "with semantic work package identifiers", with_settings: { work_packages_identifier: "semantic" } do
    it "confirms the request with the semantic identifier" do
      expect(mail.body.encoded).to include(%(and recorded it as #{work_package.identifier}.))
    end
  end

  it "is sent through the mailbox's SMTP server at the given address and reports delivery errors" do
    expect(mail.delivery_method).to be_a(ITSM::SmtpDelivery)
    expect(mail.delivery_method.settings).to include(mailbox.smtp_settings("203.0.113.10"))
    expect(mail.raise_delivery_errors).to be(true)
  end

  context "when the instance has its own SMTP settings" do
    before do
      allow(ActionMailer::Base).to receive(:smtp_settings)
        .and_return(enable_starttls_auto: true, ssl: false, openssl_verify_mode: "none", user_name: "instance")
    end

    it "uses only the given SMTP settings" do
      expect(mail.delivery_method.settings).to include(enable_starttls_auto: nil, ssl: nil, openssl_verify_mode: nil,
                                                       user_name: "relay-user")
    end
  end

  it "has no reply address" do
    expect(mail.reply_to).to be_nil
  end

  context "when the project receives emails at the sender address" do
    before do
      create(:itsm_incoming_mailbox,
             project: work_package.project,
             email: "inbox@example.com",
             aliases: ["support@example.com"])
    end

    it "has no reply address" do
      expect(mail.reply_to).to be_nil
    end
  end

  context "when the project receives emails at another address only" do
    before { create(:itsm_incoming_mailbox, project: work_package.project, email: "inbox@example.com") }

    it "lets replies go to that address" do
      expect(mail.reply_to).to eq(["inbox@example.com"])
    end
  end

  context "without a requester name" do
    let(:thread) { create(:itsm_email_thread, work_package:) }

    it "greets the requester by address" do
      expect(mail.body.encoded).to include("Hello requester@customer.example,")
    end
  end
end
