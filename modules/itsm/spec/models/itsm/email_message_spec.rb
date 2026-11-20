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

RSpec.describe ITSM::EmailMessage do
  subject(:message) { build(:itsm_email_message, thread:, message_id:, direction:, status:) }

  let(:thread) { create(:itsm_email_thread) }
  let(:message_id) { "abc@customer.example" }
  let(:direction) { "inbound" }
  let(:status) { "received" }

  it { is_expected.to be_valid }

  describe ".sent_to" do
    let!(:sent) do
      create(:itsm_email_message, thread:, direction: "outbound", status: "sent", to_addresses: ["jane@customer.example"])
    end
    let!(:failed) do
      create(:itsm_email_message, thread:, direction: "outbound", status: "failed", to_addresses: ["jane@customer.example"])
    end
    let!(:sent_to_another) do
      create(:itsm_email_message, thread:, direction: "outbound", status: "sent", to_addresses: ["bob@customer.example"])
    end
    let!(:received) { create(:itsm_email_message, thread:, to_addresses: ["jane@customer.example"]) }

    it "lists the outbound emails sent to the address" do
      expect(described_class.sent_to("jane@customer.example")).to contain_exactly(sent)
    end
  end

  describe ".referring_to" do
    let!(:reply) { create(:itsm_email_message, thread:, in_reply_to: "first@customer.example") }
    let!(:later_reply) { create(:itsm_email_message, thread:, referenced_message_ids: %w[first@customer.example]) }
    let!(:other) { create(:itsm_email_message, thread:, in_reply_to: "other@customer.example") }

    it "lists the emails replying to or referencing that Message-ID" do
      expect(described_class.referring_to("first@customer.example")).to contain_exactly(reply, later_reply)
    end
  end

  describe ".created_since" do
    let!(:recent) { create(:itsm_email_message, thread:, created_at: 1.hour.ago) }
    let!(:old) { create(:itsm_email_message, thread:, created_at: 2.days.ago) }

    it "lists the emails created from that time on" do
      expect(described_class.created_since(1.day.ago)).to contain_exactly(recent)
    end
  end

  context "with an unknown direction" do
    let(:direction) { "sideways" }

    it { is_expected.not_to be_valid }
  end

  context "with a status of the other direction" do
    let(:status) { "sent" }

    it { is_expected.not_to be_valid }
  end

  context "when an outbound message was sent" do
    let(:direction) { "outbound" }
    let(:status) { "sent" }

    it { is_expected.to be_valid }
  end

  context "with a Message-ID longer than 255 characters" do
    let(:message_id) { "#{'a' * 250}@customer.example" }

    it { is_expected.to be_valid }
  end

  context "with a Message-ID longer than a header line" do
    let(:message_id) { "#{'a' * 990}@customer.example" }

    it { is_expected.not_to be_valid }
  end

  context "with a Message-ID of fewer characters but more bytes than a header line" do
    let(:message_id) { "#{'語' * 330}@customer.example" }

    it { is_expected.not_to be_valid }
  end

  context "with addresses in mixed case, surrounding whitespace and duplicates" do
    subject(:message) do
      build(:itsm_email_message,
            from_address: " Jane@Customer.Example ",
            to_addresses: ["Support@Example.com", "support@example.com"],
            cc_addresses: [" Boss@Customer.Example", ""])
    end

    it "normalizes them" do
      expect(message).to have_attributes(from_address: "jane@customer.example",
                                         to_addresses: %w[support@example.com],
                                         cc_addresses: %w[boss@customer.example])
    end
  end

  context "without a thread" do
    let(:thread) { nil }

    it { is_expected.not_to be_valid }
  end

  context "when an outbound message has no thread" do
    let(:thread) { nil }
    let(:direction) { "outbound" }

    it { is_expected.not_to be_valid }
  end

  context "when the thread already has the message" do
    let!(:existing) { create(:itsm_email_message, thread:, message_id:) }

    it { is_expected.not_to be_valid }

    it "is rejected by the database as well" do
      expect { message.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context "when another thread has the same message" do
    let!(:existing) { create(:itsm_email_message, message_id:) }

    it { is_expected.to be_valid }
  end
end
