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

RSpec.describe ITSM::InboundEmails::ThreadAttributes do
  subject(:attributes) { described_class.new(ITSM::InboundEmail.new(raw)).to_h }

  let(:cc) { ["Colleague@Customer.example", "help@example.com", "jane@customer.example"] }
  let(:raw) { Mail.new(from: "Jane Requester <jane@customer.example>", to: "support@example.com", cc:).to_s }

  before { create(:itsm_incoming_mailbox, email: "support@example.com", aliases: ["help@example.com"]) }

  it "takes the sender as the requester and everyone else except the help desk as recipients" do
    expect(attributes).to eq(requester_email: "jane@customer.example",
                             requester_name: "Jane Requester",
                             recipients: ["colleague@customer.example"])
  end

  context "with the sender address of another help desk in CC" do
    let(:cc) { ["desk@other.example"] }

    before { create(:itsm_outgoing_mailbox, sender_email: "desk@other.example") }

    it "does not take it as a recipient" do
      expect(attributes[:recipients]).to be_empty
    end
  end

  context "when the email reached the help desk through a forwarding address" do
    let(:raw) do
      Mail.new(from: "jane@customer.example", to: "team@company.example", cc: ["colleague@customer.example"],
               "X-Original-To" => "team@company.example", "Delivered-To" => "support@example.com").to_s
    end

    it "does not take that address as a recipient" do
      expect(attributes[:recipients]).to eq(["colleague@customer.example"])
    end
  end
end
