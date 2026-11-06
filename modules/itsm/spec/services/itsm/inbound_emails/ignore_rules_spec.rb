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

RSpec.describe ITSM::InboundEmails::IgnoreRules, with_settings: { host_name: "openproject.example" } do
  subject(:reason) { described_class.new(ITSM::InboundEmail.new(raw)).reason }

  let(:from) { "jane@customer.example" }
  let(:extra_headers) { "" }
  let(:raw) { "From: #{from}\r\nTo: support@example.com\r\n#{extra_headers}Subject: Hello\r\n\r\nHello" }

  before { create(:itsm_incoming_mailbox, email: "support@example.com", aliases: ["help@example.com"]) }

  it "ignores nothing in a normal email" do
    expect(reason).to be_nil
  end

  context "with an automatic reply" do
    let(:extra_headers) { "Auto-Submitted: auto-replied\r\n" }

    it { is_expected.to eq(:automatic) }
  end

  context "with Auto-Submitted: no" do
    let(:extra_headers) { "Auto-Submitted: no\r\n" }

    it { is_expected.to be_nil }
  end

  %w[X-Autoreply X-Autorespond List-Unsubscribe].each do |name|
    context "with #{name}" do
      let(:extra_headers) { "#{name}: yes\r\n" }

      it { is_expected.to eq(:automatic) }
    end
  end

  %w[bulk list junk auto_reply].each do |precedence|
    context "with Precedence: #{precedence}" do
      let(:extra_headers) { "Precedence: #{precedence}\r\n" }

      it { is_expected.to eq(:automatic) }
    end
  end

  context "with X-Precedence: bulk" do
    let(:extra_headers) { "X-Precedence: Bulk\r\n" }

    it { is_expected.to eq(:automatic) }
  end

  context "with a delivery status notification" do
    let(:extra_headers) { "Content-Type: multipart/report; report-type=delivery-status; boundary=report\r\n" }

    it { is_expected.to eq(:automatic) }
  end

  context "with an email sent by this OpenProject" do
    let(:extra_headers) { "X-OpenProject-Host: openproject.example\r\nAuto-Submitted: auto-generated\r\n" }

    it { is_expected.to eq(:sent_by_openproject) }
  end

  context "with an email sent by another OpenProject" do
    let(:extra_headers) { "X-OpenProject-Host: other.example\r\nAuto-Submitted: auto-generated\r\n" }

    it { is_expected.to eq(:automatic) }
  end

  context "with a sender that is one of our help desk addresses" do
    let(:from) { "Help@Example.com" }

    it { is_expected.to eq(:sent_by_helpdesk) }
  end
end
