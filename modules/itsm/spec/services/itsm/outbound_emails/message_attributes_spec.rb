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

RSpec.describe ITSM::OutboundEmails::MessageAttributes do
  subject(:attributes) { described_class.new(thread, mailbox).to_h }

  let(:work_package) { create(:work_package, subject: "Printer is broken") }
  let(:thread) do
    create(:itsm_email_thread, work_package:, requester_email: "jane@customer.example", recipients: ["bob@customer.example"])
  end
  let(:mailbox) { build(:itsm_outgoing_mailbox, sender_email: "support@example.com", sender_name: "Support") }

  it "builds a queued outbound email from the mailbox to the requester and the recipients" do
    expect(attributes).to include(direction: :outbound,
                                  status: :queued,
                                  from_address: "support@example.com",
                                  from_name: "Support",
                                  to_addresses: ["jane@customer.example"],
                                  cc_addresses: ["bob@customer.example"],
                                  subject: "[##{work_package.id}] Printer is broken")
  end

  it "gives it a new Message-ID on the sender's domain" do
    expect(attributes[:message_id]).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}@example\.com\z/)
    expect(described_class.new(thread, mailbox).to_h[:message_id]).not_to eq(attributes[:message_id])
  end

  context "with received emails" do
    before do
      create(:itsm_email_message, thread:, message_id: "first@customer.example", created_at: 2.hours.ago)
      create(:itsm_email_message, thread:, message_id: "second@customer.example", created_at: 1.hour.ago)
      create(:itsm_email_message, thread:, direction: "outbound", status: "sent", message_id: "ours@example.com")
    end

    it "replies to the last one and refers to all of them" do
      expect(attributes).to include(in_reply_to: "second@customer.example",
                                    referenced_message_ids: %w[first@customer.example second@customer.example])
    end
  end

  context "without received emails" do
    it "replies to nothing" do
      expect(attributes).to include(in_reply_to: nil, referenced_message_ids: [])
    end
  end

  context "with semantic work package identifiers", with_settings: { work_packages_identifier: "semantic" } do
    it "puts the semantic identifier into the subject" do
      expect(attributes[:subject]).to eq("[#{work_package.identifier}] Printer is broken")
    end
  end
end
