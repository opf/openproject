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

RSpec.describe ITSM::InboundEmails::ReplyThread do
  subject(:thread) { described_class.find(ITSM::InboundEmail.new(raw), project) }

  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:request) do
    create(:itsm_email_thread, work_package:, requester_email: "jane@customer.example",
                               recipients: ["colleague@customer.example"])
  end
  let!(:confirmation) do
    create(:itsm_email_message, thread: request, direction: "outbound", status: "sent",
                                message_id: "confirmation@example.com", in_reply_to: "request@customer.example",
                                referenced_message_ids: ["request@customer.example"])
  end
  let(:from) { "jane@customer.example" }
  let(:email_subject) { "Re: Printer broken" }
  let(:headers) { { in_reply_to: "<confirmation@example.com>" } }
  let(:raw) { Mail.new(message_id: "<reply@customer.example>", from:, subject: email_subject, **headers).to_s }

  it "finds the request the email replies to" do
    expect(thread).to eq(request)
  end

  context "when someone outside the request replies" do
    let(:from) { "stranger@elsewhere.example" }

    it "finds the request, as only those who got the email know its ID" do
      expect(thread).to eq(request)
    end
  end

  context "when the email refers to the request only in its References" do
    let(:headers) { { references: "<other@customer.example> <confirmation@example.com>" } }

    it { is_expected.to eq(request) }
  end

  context "when a reply to the email was processed before it" do
    let(:raw) { Mail.new(message_id: "<request@customer.example>", from:, subject: "Printer broken").to_s }

    it "finds the request of the reply" do
      expect(thread).to eq(request)
    end
  end

  context "when the email replies to a message of another project" do
    let(:work_package) { create(:work_package) }

    it { is_expected.to be_nil }
  end

  context "when the email refers to no stored message" do
    let(:headers) { { in_reply_to: "<unknown@customer.example>" } }

    it { is_expected.to be_nil }

    context "with the work package in the subject" do
      let(:email_subject) { "Re: [##{work_package.id}] Printer broken" }

      it "finds the request" do
        expect(thread).to eq(request)
      end

      context "when a recipient writes" do
        let(:from) { "colleague@customer.example" }

        it { is_expected.to eq(request) }
      end

      context "when someone else writes" do
        let(:from) { "stranger@elsewhere.example" }

        it { is_expected.to be_nil }
      end

      context "when the work package is in another project" do
        let(:work_package) { create(:work_package) }

        it { is_expected.to be_nil }
      end
    end

    context "with the semantic work package identifier in the subject",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:email_subject) { "Re: [#{work_package.reload.identifier}] Printer broken" }

      it "finds the request" do
        expect(thread).to eq(request)
      end
    end

    context "with a work package in the subject that did not come by email" do
      let(:email_subject) { "Re: [##{create(:work_package, project:).id}] Printer broken" }

      it { is_expected.to be_nil }
    end
  end
end
