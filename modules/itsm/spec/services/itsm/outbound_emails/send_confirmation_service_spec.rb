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

RSpec.describe ITSM::OutboundEmails::SendConfirmationService do
  subject(:result) { described_class.new.call(thread:) }

  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:, subject: "Printer is broken") }
  let(:thread) { create(:itsm_email_thread, work_package:, recipients: ["colleague@customer.example"]) }
  let(:mail_server) { create(:itsm_mail_server, :smtp) }
  let(:addresses) { [IPAddr.new("203.0.113.10")] }
  let(:delivered) { ActionMailer::Base.deliveries.last }
  let(:sent_message) { result.result }

  let!(:request) { create(:itsm_email_message, thread:, message_id: "request@customer.example") }
  let!(:outgoing_mailbox) do
    create(:itsm_outgoing_mailbox, project:, mail_server:, sender_email: "support@example.com", sender_name: "Support")
  end

  before do
    with_ssrf_ip_allowlist(%w[203.0.113.10 203.0.113.11])
    allow(OpenProject::SsrfProtection).to receive(:resolver).and_return(->(_host) { addresses })
    allow(ITSM::HelpdeskMailer).to receive(:mailbox_delivery_method).and_return(:test)
  end

  it "sends the confirmation to the requester and the recipients" do
    expect(result).to be_success
    expect(delivered).to have_attributes(from: ["support@example.com"],
                                         to: ["requester@customer.example"],
                                         cc: ["colleague@customer.example"],
                                         subject: "[##{work_package.id}] Printer is broken",
                                         in_reply_to: "request@customer.example")
  end

  it "stores the sent email on the thread" do
    expect(sent_message).to have_attributes(thread:,
                                            direction: "outbound",
                                            status: "sent",
                                            message_id: delivered.message_id,
                                            to_addresses: ["requester@customer.example"],
                                            cc_addresses: ["colleague@customer.example"])
  end

  it "connects to the checked address of the SMTP server" do
    expect(result).to be_success
    expect(delivered.delivery_method.settings).to include(address: "203.0.113.10", tls_hostname: "smtp.example.com")
  end

  context "when the confirmation was already sent" do
    let!(:confirmation) do
      create(:itsm_email_message, thread:, direction: "outbound", status: "sent", from_address: "support@example.com")
    end

    it "returns it without sending another one" do
      expect(result).to be_success
      expect(sent_message).to eq(confirmation)
      expect(ActionMailer::Base.deliveries).to be_empty
      expect(thread.messages.outbound).to contain_exactly(confirmation)
    end
  end

  context "when an earlier confirmation could not be sent" do
    let!(:failed_confirmation) do
      create(:itsm_email_message, thread:, direction: "outbound", status: "failed", from_address: "support@example.com")
    end

    it "sends the same email again" do
      expect(result).to be_success
      expect(sent_message).to eq(failed_confirmation)
      expect(sent_message).to have_attributes(status: "sent", message_id: failed_confirmation.message_id)
      expect(delivered.message_id).to eq(failed_confirmation.message_id)
      expect(thread.messages.outbound.count).to eq(1)
    end
  end

  context "with several outgoing mailboxes" do
    before { create(:itsm_outgoing_mailbox, project:, sender_email: "other@example.com") }

    it "sends from the first one" do
      expect(result).to be_success
      expect(delivered.from).to eq(["support@example.com"])
    end
  end

  context "when a recipient's domain is blocked", with_settings: { blocked_email_domains: "other.example" } do
    let(:thread) { create(:itsm_email_thread, work_package:, recipients: ["colleague@other.example"]) }

    it "stores only the addresses the email was sent to" do
      expect(result).to be_success
      expect(delivered.cc).to be_blank
      expect(sent_message).to have_attributes(to_addresses: ["requester@customer.example"], cc_addresses: [])
    end
  end

  context "when all recipients' domains are blocked", with_settings: { blocked_email_domains: "customer.example" } do
    it "stores the email as not sent" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:not_delivered])
      expect(sent_message.reload).to have_attributes(status: "failed")
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  context "when the project has no outgoing mailbox" do
    let!(:outgoing_mailbox) { nil }

    it "sends nothing" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:no_outgoing_mailbox])
      expect(ActionMailer::Base.deliveries).to be_empty
      expect(ITSM::EmailMessage.outbound).to be_empty
    end
  end

  context "when the SMTP server address is not allowed" do
    let(:addresses) { [IPAddr.new("10.0.0.5")] }

    it "sends nothing" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:address_not_allowed])
      expect(ITSM::EmailMessage.outbound).to be_empty
    end
  end

  context "when the SMTP server cannot be resolved" do
    let(:addresses) { [] }

    it "sends nothing" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:unreachable])
      expect(ITSM::EmailMessage.outbound).to be_empty
    end
  end

  context "when the first address of the SMTP server refuses the connection" do
    let(:addresses) { [IPAddr.new("203.0.113.10"), IPAddr.new("203.0.113.11")] }
    let(:refusing) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(ITSM::HelpdeskMailer).to receive(:confirmation).and_call_original
      allow(ITSM::HelpdeskMailer).to receive(:confirmation).with(anything, anything, "203.0.113.10").and_return(refusing)
      allow(refusing).to receive(:deliver_now).and_raise(Errno::ECONNREFUSED)
    end

    it "sends through the next one" do
      expect(result).to be_success
      expect(delivered.delivery_method.settings).to include(address: "203.0.113.11")
    end
  end

  context "when every address of the SMTP server refuses the connection" do
    let(:addresses) { [IPAddr.new("203.0.113.10"), IPAddr.new("203.0.113.11")] }
    let(:refusing) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(ITSM::HelpdeskMailer).to receive(:confirmation).and_return(refusing)
      allow(refusing).to receive(:deliver_now).and_raise(Errno::ECONNREFUSED)
    end

    it "stores the email as failed, to be sent again" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:delivery_failed])
      expect(sent_message.reload).to have_attributes(status: "failed", error_message: include("Connection refused"))
      expect(ITSM::HelpdeskMailer).to have_received(:confirmation).twice
    end
  end

  context "when the requester got many confirmations within a day" do
    before do
      create_list(:itsm_email_message, described_class::CONFIRMATIONS_PER_REQUESTER,
                  direction: "outbound", status: "sent", to_addresses: ["requester@customer.example"])
    end

    it "sends nothing, so that two mail systems cannot answer each other forever" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:too_many_confirmations])
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  context "when the requester got many confirmations before that" do
    before do
      create_list(:itsm_email_message, described_class::CONFIRMATIONS_PER_REQUESTER,
                  direction: "outbound",
                  status: "sent",
                  to_addresses: ["requester@customer.example"],
                  created_at: (described_class::CONFIRMATIONS_PERIOD + 1.hour).ago)
    end

    it "sends the confirmation" do
      expect(result).to be_success
      expect(delivered.to).to eq(["requester@customer.example"])
    end
  end

  context "when the SMTP server rejects the email" do
    let(:smtp_error) { Net::SMTPFatalError.new(Net::SMTP::Response.parse("550 5.7.1 message rejected")) }
    let(:delivery) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(ITSM::HelpdeskMailer).to receive(:confirmation).and_return(delivery)
      allow(delivery).to receive(:deliver_now).and_raise(smtp_error)
    end

    it "stores the email as failed for good" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:delivery_rejected])
      expect(sent_message.reload).to have_attributes(status: "failed", error_message: include("550"))
    end
  end

  context "when the SMTP server does not accept the mailbox credentials" do
    let(:smtp_error) { Net::SMTPAuthenticationError.new(Net::SMTP::Response.parse("535 5.7.8 authentication failed")) }
    let(:delivery) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(ITSM::HelpdeskMailer).to receive(:confirmation).and_return(delivery)
      allow(delivery).to receive(:deliver_now).and_raise(smtp_error)
    end

    it "stores the email as failed, to be sent again once the credentials are fixed" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:delivery_failed])
      expect(sent_message.reload).to have_attributes(status: "failed", error_message: include("535"))
    end
  end

  context "when the SMTP server cannot take the email right now" do
    let(:smtp_error) { Net::SMTPServerBusy.new(Net::SMTP::Response.parse("451 4.3.0 try again later")) }
    let(:delivery) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(ITSM::HelpdeskMailer).to receive(:confirmation).and_return(delivery)
      allow(delivery).to receive(:deliver_now).and_raise(smtp_error)
    end

    it "stores the email as failed, to be sent again" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:delivery_failed])
      expect(sent_message.reload).to have_attributes(status: "failed", error_message: include("451"))
    end
  end

  context "when the email was sent but storing that fails" do
    let(:delivery) { instance_double(ActionMailer::MessageDelivery) }
    let(:email) { instance_double(Mail::Message, perform_deliveries: true) }

    before do
      allow(ITSM::HelpdeskMailer).to receive(:confirmation).and_return(delivery)
      allow(delivery).to receive(:deliver_now).and_return(email)
      allow(email).to receive(:to).and_raise(ActiveRecord::StatementInvalid)
    end

    it "raises instead of storing the email as not sent" do
      expect { result }.to raise_error(ActiveRecord::StatementInvalid)
      expect(ITSM::EmailMessage.outbound.failed).to be_empty
    end
  end

  context "when sending fails unexpectedly" do
    let(:delivery) { instance_double(ActionMailer::MessageDelivery) }

    before do
      allow(ITSM::HelpdeskMailer).to receive(:confirmation).and_return(delivery)
      allow(delivery).to receive(:deliver_now).and_raise(ArgumentError, "unexpected")
      allow(OpenProject.logger).to receive(:error)
    end

    it "stores the email as failed and reports the error" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:delivery_failed])
      expect(sent_message.reload).to have_attributes(status: "failed", error_message: "ArgumentError")
      expect(OpenProject.logger).to have_received(:error)
        .with(/failed \(ArgumentError\)/, exception: an_instance_of(ArgumentError))
    end
  end
end
