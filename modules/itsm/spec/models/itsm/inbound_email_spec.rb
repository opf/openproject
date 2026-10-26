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

RSpec.describe ITSM::InboundEmail do
  subject(:headers) { email.headers }

  let(:email) { described_class.new(raw) }
  let(:raw) do
    Mail.new(
      message_id: "<request-1@customer.example>",
      in_reply_to: "<answer-1@openproject.example>",
      references: "<request-0@customer.example> <answer-1@openproject.example>",
      from: "Jane Requester <jane@customer.example>",
      to: "support@example.com",
      cc: ["colleague@customer.example", "boss@customer.example"],
      subject: "=?UTF-8?Q?Dr=C3=BCcker_kaputt?=",
      body: "The printer is broken."
    ).to_s
  end

  it "reads the headers" do
    expect(headers).to eq(
      described_class::Headers.new(
        message_id: "request-1@customer.example",
        in_reply_to: "answer-1@openproject.example",
        references: %w[request-0@customer.example answer-1@openproject.example],
        from_address: "jane@customer.example",
        from_name: "Jane Requester",
        to_addresses: %w[support@example.com],
        cc_addresses: %w[colleague@customer.example boss@customer.example],
        subject: "Drücker kaputt"
      )
    )
  end

  it "keeps the email content out of inspect" do
    headers

    expect(email.inspect).not_to include("jane@customer.example", "printer")
  end

  context "without optional headers" do
    let(:raw) { "From: jane@customer.example\r\nTo: support@example.com\r\n\r\nHello" }

    it "has no reply information, no CCs and no subject" do
      expect(headers).to have_attributes(in_reply_to: nil, references: [], cc_addresses: [], from_name: nil, subject: nil)
    end

    it "derives a stable message ID from the content" do
      expect(headers.message_id).to eq(described_class.new(raw.dup).headers.message_id)
      expect(headers.message_id).to end_with("@openproject.invalid")
    end
  end

  context "with a sender that is not an email address" do
    let(:raw) { "From: not an address at all\r\nTo: support@example.com\r\n\r\nHello" }

    it "has no sender name" do
      expect(headers.from_name).to be_nil
    end
  end

  context "with header bytes that are not valid UTF-8" do
    let(:raw) { "From: jane@customer.example\r\nSubject: \xFF\xFEPrinter\r\n\r\nHello".b }

    it "replaces them" do
      expect(headers.subject).to eq("��Printer")
    end
  end
end
