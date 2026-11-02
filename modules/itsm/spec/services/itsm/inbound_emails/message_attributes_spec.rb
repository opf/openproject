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

RSpec.describe ITSM::InboundEmails::MessageAttributes do
  subject(:attributes) { described_class.new(ITSM::InboundEmail.new(raw)).to_h }

  let(:raw) do
    Mail.new(message_id: "<request-1@customer.example>",
             in_reply_to: "<answer-1@openproject.example>",
             references: "<request-0@customer.example> <answer-1@openproject.example>",
             from: "Jane Requester <jane@customer.example>",
             to: "support@example.com",
             cc: "colleague@customer.example",
             subject: "Printer broken").to_s
  end

  it "takes the email's headers as an inbound message" do
    expect(attributes).to eq(direction: :inbound,
                             message_id: "request-1@customer.example",
                             in_reply_to: "answer-1@openproject.example",
                             referenced_message_ids: %w[request-0@customer.example answer-1@openproject.example],
                             from_address: "jane@customer.example",
                             from_name: "Jane Requester",
                             to_addresses: ["support@example.com"],
                             cc_addresses: ["colleague@customer.example"],
                             subject: "Printer broken")
  end
end
