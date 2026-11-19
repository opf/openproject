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

RSpec.describe ITSM::OutboundEmails::SendReplyService do
  subject(:result) { described_class.new.call(journal:) }

  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:, subject: "Printer is broken") }
  let(:journal) { create(:work_package_journal, journable: work_package, notes: "We replaced the toner.", version: 2) }
  let(:thread) { create(:itsm_email_thread, work_package:, recipients: ["colleague@customer.example"]) }
  let(:delivered) { ActionMailer::Base.deliveries.last }
  let(:sent_message) { result.result }

  let!(:request) { create(:itsm_email_message, thread:, message_id: "request@customer.example") }
  let!(:outgoing_mailbox) do
    create(:itsm_outgoing_mailbox, project:, sender_email: "support@example.com", sender_name: "Support")
  end

  before do
    with_ssrf_ip_allowlist(%w[203.0.113.10])
    allow(OpenProject::SsrfProtection).to receive(:resolver).and_return(->(_host) { [IPAddr.new("203.0.113.10")] })
    allow(ITSM::HelpdeskMailer).to receive(:mailbox_delivery_method).and_return(:test)
  end

  it "sends the comment to the requester and the recipients as a reply to the request" do
    expect(result).to be_success
    expect(delivered).to have_attributes(from: ["support@example.com"],
                                         to: ["requester@customer.example"],
                                         cc: ["colleague@customer.example"],
                                         subject: "[##{work_package.id}] Printer is broken",
                                         in_reply_to: "request@customer.example")
    expect(delivered.body.encoded).to include("We replaced the toner.")
  end

  it "stores the sent email for the comment" do
    expect(sent_message).to have_attributes(thread:,
                                            journal:,
                                            direction: "outbound",
                                            status: "sent",
                                            message_id: delivered.message_id)
  end

  context "when the reply was already sent" do
    let!(:reply) do
      create(:itsm_email_message, thread:, journal:, direction: "outbound", status: "sent", from_address: "support@example.com")
    end

    it "returns it without sending another one" do
      expect(result).to be_success
      expect(sent_message).to eq(reply)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  context "when an earlier try could not be sent" do
    let!(:failed_reply) do
      create(:itsm_email_message, thread:, journal:, direction: "outbound", status: "failed", from_address: "support@example.com")
    end

    it "sends the same email again" do
      expect(result).to be_success
      expect(sent_message).to eq(failed_reply)
      expect(delivered.message_id).to eq(failed_reply.message_id)
    end
  end

  context "when the confirmation of the request could not be sent" do
    let!(:failed_confirmation) do
      create(:itsm_email_message, thread:, direction: "outbound", status: "failed", from_address: "support@example.com")
    end

    it "sends the reply as an email of its own" do
      expect(result).to be_success
      expect(sent_message).not_to eq(failed_confirmation)
      expect(failed_confirmation.reload).to have_attributes(status: "failed", journal: nil)
    end
  end

  context "when the project has no outgoing mailbox" do
    let!(:outgoing_mailbox) { nil }

    it "sends nothing" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:no_outgoing_mailbox])
      expect(ITSM::EmailMessage.replies_to(journal)).to be_empty
    end
  end

  context "when the requester got many confirmations within a day" do
    before do
      create_list(:itsm_email_message, ITSM::OutboundEmails::SendConfirmationService::CONFIRMATIONS_PER_REQUESTER,
                  direction: "outbound", status: "sent", to_addresses: ["requester@customer.example"])
    end

    it "still sends the reply" do
      expect(result).to be_success
    end
  end
end
