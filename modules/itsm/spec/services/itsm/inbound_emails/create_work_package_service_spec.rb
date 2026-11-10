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

RSpec.describe ITSM::InboundEmails::CreateWorkPackageService do
  subject(:result) { described_class.new(user:).call(mailbox:, email: ITSM::InboundEmail.new(raw)) }

  let(:project) { create(:project_with_types) }
  let(:permissions) { %i[view_work_packages add_work_packages add_work_package_comments] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:mailbox) { create(:itsm_incoming_mailbox, project:, email: "support@example.com", aliases: ["help@example.com"]) }
  let(:message_id) { "request-1@customer.example" }
  let(:from) { "Jane Requester <jane@customer.example>" }
  let(:cc) { ["Colleague@Customer.example", "help@example.com", "jane@customer.example"] }
  let(:email_subject) { "Printer broken" }
  let(:body) { "The printer on floor 2 is broken." }
  let(:raw) do
    Mail.new(message_id: "<#{message_id}>", from:, to: "support@example.com", cc:, subject: email_subject, body:).to_s
  end
  let(:work_package) { result.result.work_package }
  let!(:status) { create(:default_status) }
  let!(:priority) { create(:default_priority) }

  it "creates a work package in the mailbox's project" do
    expect(result).to be_success
    expect(work_package).to have_attributes(project:, author: user, subject: "Printer broken",
                                            type: project.enabled_types.first, status:, priority:)
  end

  it "puts the email text in a code block" do
    expect(work_package.description).to eq("```\nThe printer on floor 2 is broken.\n```")
  end

  it "notes in the activity that the work package came by email" do
    expect(work_package.journals.first.cause).to eq("type" => "email", "sender_address" => "jane@customer.example")
  end

  it "records the sender as the requester and everyone else except the help desk as recipients" do
    expect(result.result).to have_attributes(requester_email: "jane@customer.example",
                                             requester_name: "Jane Requester",
                                             recipients: ["colleague@customer.example"])
  end

  it "records the email as a processed inbound message of the work package's first journal" do
    expect(result.result.messages.sole).to have_attributes(
      direction: "inbound",
      status: "processed",
      journal: work_package.journals.first,
      message_id: "request-1@customer.example",
      from_address: "jane@customer.example",
      from_name: "Jane Requester",
      to_addresses: ["support@example.com"],
      cc_addresses: %w[colleague@customer.example help@example.com jane@customer.example],
      subject: "Printer broken"
    )
  end

  context "when the email was already processed in this project" do
    let!(:earlier_result) { described_class.new(user:).call(mailbox:, email: ITSM::InboundEmail.new(raw)) }

    it "returns the existing thread without creating anything" do
      expect { result }.not_to change(WorkPackage, :count)
      expect(result.result).to eq(earlier_result.result)
    end
  end

  context "when the same email was processed in another project" do
    before { create(:itsm_email_message, message_id:) }

    it "creates a work package in this project" do
      expect { result }.to change { WorkPackage.where(project:).count }.by(1)
    end
  end

  context "without a sender" do
    let(:raw) { "Message-ID: <#{message_id}>\r\nTo: support@example.com\r\nSubject: Hello\r\n\r\nHello" }

    it "fails without creating a work package" do
      expect { result }.not_to change(WorkPackage, :count)
      expect(result).to be_failure
      expect(result.errors.symbols_for(:requester_email)).to eq([:blank])
    end
  end

  context "when the user may not add work packages" do
    let(:permissions) { %i[view_work_packages add_work_package_comments] }

    it "fails without creating a thread" do
      expect { result }.not_to change(ITSM::EmailThread, :count)
      expect(result).to be_failure
    end
  end

  context "when the user may not comment on work packages" do
    let(:permissions) { %i[view_work_packages add_work_packages] }

    it "fails without keeping the work package" do
      expect(result.errors.symbols_for(:base)).to eq([:error_unauthorized])
      expect(WorkPackage.where(project:)).to be_empty
    end
  end

  context "when the email cannot be stored" do
    let(:message_id) { "#{'a' * 1000}@customer.example" }

    it "fails without keeping the work package" do
      expect(result.errors.symbols_for(:message_id)).to eq([:too_long])
      expect(WorkPackage.where(project:)).to be_empty
    end
  end
end
