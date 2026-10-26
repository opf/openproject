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

RSpec.describe ITSM::EmailMessages::ReceiveService, with_flag: { helpdesk: true } do
  subject(:result) { described_class.new(mailbox:, user:).call(raw:) }

  let(:mailbox) { create(:itsm_mailbox) }
  let(:user) { User.system }
  let(:raw) do
    "Message-ID: <request-1@customer.example>\r\n" \
      "From: Jane Requester <jane@customer.example>\r\n" \
      "To: #{mailbox.email}\r\n" \
      "Subject: Printer broken\r\n\r\n" \
      "The printer is broken."
  end

  it "stores the email as received" do
    expect(result).to be_success
    expect(result.result).to have_attributes(
      mailbox:,
      thread: nil,
      direction: "inbound",
      status: "received",
      message_id: "request-1@customer.example",
      from_address: "jane@customer.example",
      from_name: "Jane Requester",
      to_addresses: [mailbox.email],
      subject: "Printer broken"
    )
  end

  context "when the email was already received" do
    let!(:existing) { create(:itsm_email_message, mailbox:, thread: nil, message_id: "request-1@customer.example") }

    it "succeeds with the stored message without storing it again" do
      expect { result }.not_to change(ITSM::EmailMessage, :count)
      expect(result).to have_attributes(success?: true, result: existing)
    end
  end

  context "when another mailbox already received the same email" do
    before { create(:itsm_email_message, thread: nil, message_id: "request-1@customer.example") }

    it "stores it for this mailbox" do
      expect(result).to be_success
      expect(result.result.mailbox).to eq(mailbox)
    end
  end

  context "without a sender" do
    let(:raw) { "Message-ID: <request-1@customer.example>\r\nSubject: Printer broken\r\n\r\nHello" }

    it "does not store it" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:from_address)).to include(:blank)
    end
  end

  context "when the helpdesk is disabled in the project" do
    let(:mailbox) { create(:itsm_mailbox, project: create(:project, disable_modules: :helpdesk)) }

    it "does not store it" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to include(:error_unauthorized)
    end
  end
end
