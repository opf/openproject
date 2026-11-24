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

RSpec.describe ITSM::InboundEmails::AddReplyService do
  subject(:result) { described_class.new(user:).call(thread: request, email: ITSM::InboundEmail.new(raw)) }

  let(:project) { create(:project) }
  let(:permissions) { %i[view_work_packages add_work_package_comments add_work_package_attachments] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let(:work_package) { create(:work_package, project:) }
  let(:request) { create(:itsm_email_thread, work_package:, requester_email: "jane@customer.example") }
  let(:body) { "It works again.\n\nOn Fri, Help desk wrote:\n> we have received your request." }
  let(:files) { {} }
  let(:raw) do
    Mail.new(message_id: "<reply@customer.example>", in_reply_to: "<confirmation@example.com>",
             from: "jane@customer.example", to: "support@example.com", subject: "Re: [DP-25] Printer broken", body:)
      .tap { |mail| files.each { |filename, content| mail.add_file(filename:, content:) } }
      .to_s
  end
  let(:comment) { work_package.journals.reload.last }

  it "adds the reply without the quoted email as a comment of the user" do
    expect { result }.to change { work_package.journals.count }.by(1)
    expect(comment).to have_attributes(user:, notes: "```\nIt works again.\n```")
  end

  it "notes in the activity that the comment came by email" do
    result

    expect(comment.cause).to eq("type" => "email", "sender_address" => "jane@customer.example")
  end

  it "records the reply as a processed inbound message of the comment" do
    expect(result).to be_success
    expect(result.result).to have_attributes(thread: request, journal: comment, direction: "inbound", status: "processed",
                                             message_id: "reply@customer.example", in_reply_to: "confirmation@example.com")
    expect(result.result).to be_previously_new_record
  end

  context "with attachments" do
    let(:files) { { "report.txt" => "The report." } }

    it "adds them to the work package, in the comment's activity entry" do
      expect { result }.to change { work_package.journals.count }.by(1)
      expect(work_package.attachments.map(&:filename)).to eq(["report.txt"])
      expect(comment.attachable_journals.map(&:filename)).to eq(["report.txt"])
    end

    context "when the user may not add attachments" do
      let(:permissions) { %i[view_work_packages add_work_package_comments] }

      it "adds the comment and notes the skipped files below it" do
        expect(result).to be_success
        expect(work_package.attachments).to be_empty
        expect(comment.notes)
          .to eq("```\nIt works again.\n```\n\nNot attached: `report.txt` (attachments not allowed on this work package)")
      end
    end

    context "when the comment is not added" do
      let(:permissions) { %i[view_work_packages add_work_package_attachments] }

      it "deletes them, as the email is kept to be tried again" do
        expect(result).to be_failure
        expect(Attachment.count).to eq(0)
      end
    end
  end

  context "when the reply was already added" do
    before { described_class.new(user:).call(thread: request, email: ITSM::InboundEmail.new(raw)) }

    it "returns the stored message without adding another comment" do
      expect { result }.not_to change(work_package.journals, :count)
      expect(result.result).not_to be_previously_new_record
    end
  end

  context "when the reply is only quoted text" do
    let(:body) { "> we have received your request." }

    it "adds the whole text" do
      result

      expect(comment.notes).to eq("```\n> we have received your request.\n```")
    end
  end

  context "when the reply has no text" do
    let(:body) { "" }

    it "adds a comment saying so" do
      result

      expect(comment.notes).to eq("```\n(no text)\n```")
    end
  end

  context "when the work package is closed" do
    let(:work_package) { create(:work_package, project:, status: create(:closed_status)) }

    it "adds the comment without changing the status" do
      expect { result }.to change { work_package.journals.count }.by(1)
      expect(work_package.reload.status).to be_closed
    end
  end

  context "when the user may not comment" do
    let(:permissions) { %i[view_work_packages] }

    it "fails as unauthorized and stores nothing" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:journal_notes)).to include(:error_unauthorized)
      expect(ITSM::EmailMessage.count).to eq(0)
    end
  end

  context "when the message cannot be stored" do
    let(:raw) { "Message-ID: <#{'x' * 1000}@customer.example>\r\nFrom: jane@customer.example\r\n\r\nIt works again." }

    it "fails without adding the comment" do
      expect { result }.not_to change(work_package.journals, :count)
      expect(result).to be_failure
      expect(result.result).to be_a(ITSM::EmailMessage)
    end
  end
end
