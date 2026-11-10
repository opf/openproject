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

RSpec.describe ITSM::Mailboxes::ProcessEmailService do
  include_context "with a connected IMAP session"

  after { session.close }

  subject(:result) { described_class.new(mailbox:, session:).call(uid: 7) }

  let(:project) { create(:project_with_types) }
  let(:mailbox) { create(:itsm_incoming_mailbox, project:, email: "support@example.com") }
  let(:headers) { {} }
  let(:raw) do
    Mail.new(message_id: "<request-1@customer.example>", from: "jane@customer.example", to: "support@example.com",
             subject: "Printer broken", body: "The printer is broken.", **headers).to_s
  end
  let(:fetched) { [Net::IMAP::FetchData.new(7, { "BODY[]" => raw })] }
  let(:logged) { [] }
  let(:warned) { [] }
  let!(:status) { create(:default_status) }
  let!(:priority) { create(:default_priority) }

  before do
    allow(imap).to receive_messages(uid_fetch: fetched, uid_store: nil, uid_expunge: nil, capable?: true)
    allow(Rails.logger).to receive(:tagged).and_call_original
    allow(Rails.logger).to receive(:info) { |&message| logged << message.call }
    allow(Rails.logger).to receive(:warn) { |&message| warned << message.call }
  end

  it "creates a work package as the system user and removes the email from the server" do
    expect { result }.to change { WorkPackage.where(project:, author: User.system).count }.by(1)
    expect(result).to be_success
    expect(imap).to have_received(:uid_store).with(7, "+FLAGS", [:Deleted])
    expect(imap).to have_received(:uid_expunge).with(7)
  end

  it "queues the confirmation for the new work package" do
    result

    expect(ITSM::OutboundEmails::SendConfirmationJob)
      .to have_been_enqueued.with(ITSM::EmailThread.find_by!(work_package: WorkPackage.last))
  end

  it "logs the work package, tagged with the Message-ID" do
    result

    expect(Rails.logger).to have_received(:tagged).with("email request-1@customer.example")
    expect(logged).to include("Added to work package ##{WorkPackage.last.id}")
  end

  context "when the email was already processed" do
    before { described_class.new(mailbox:, session:).call(uid: 7) }

    it "removes it without creating another work package or confirming it again" do
      expect { result }.not_to change(WorkPackage, :count)
      expect(ITSM::OutboundEmails::SendConfirmationJob).to have_been_enqueued.once
      expect(imap).to have_received(:uid_expunge).with(7).twice
      expect(logged).to include("Already in work package ##{WorkPackage.last.id}")
    end
  end

  context "when the email is an automatic reply" do
    let(:headers) { { "Auto-Submitted" => "auto-replied" } }

    it "removes it without creating a work package" do
      expect { result }.not_to change(WorkPackage, :count)
      expect(imap).to have_received(:uid_expunge).with(7)
      expect(logged).to include("Ignored (automatic)")
      expect(ITSM::OutboundEmails::SendConfirmationJob).not_to have_been_enqueued
    end
  end

  context "when the email replies to a message of the project" do
    let(:headers) { { in_reply_to: "<earlier@customer.example>" } }

    before do
      create(:itsm_email_message, message_id: "earlier@customer.example",
                                  thread: create(:itsm_email_thread, work_package: create(:work_package, project:)))
    end

    it "marks it as seen and leaves it on the server" do
      expect { result }.not_to change(WorkPackage, :count)
      expect(imap).to have_received(:uid_store).with(7, "+FLAGS", [:Seen])
      expect(imap).not_to have_received(:uid_expunge)
      expect(logged).to include("Not processed (reply)")
      expect(ITSM::OutboundEmails::SendConfirmationJob).not_to have_been_enqueued
    end
  end

  context "when the email replies to a message of another project" do
    let(:headers) { { in_reply_to: "<earlier@customer.example>" } }

    before { create(:itsm_email_message, message_id: "earlier@customer.example") }

    it "creates a work package" do
      expect { result }.to change { WorkPackage.where(project:).count }.by(1)
    end
  end

  context "when no work package can be created" do
    let(:raw) { "Message-ID: <request-1@customer.example>\r\nTo: support@example.com\r\nSubject: Hello\r\n\r\nHello" }

    it "marks it as seen and warns with the reason" do
      expect(result).to be_success
      expect(imap).to have_received(:uid_store).with(7, "+FLAGS", [:Seen])
      expect(imap).not_to have_received(:uid_expunge)
      expect(warned).to include("Not processed (requester_email blank)")
      expect(ITSM::OutboundEmails::SendConfirmationJob).not_to have_been_enqueued
    end
  end

  context "when the project's setup lets no work package be created" do
    let!(:priority) { nil }

    it "fails and leaves the email untouched, to be tried again" do
      expect { result }.not_to change(WorkPackage, :count)
      expect(result.errors.symbols_for(:base)).to eq([:work_package_not_created])
      expect(imap).not_to have_received(:uid_store)
      expect(warned).to include("Work package not created (priority blank)")
    end
  end

  context "when the author may not create work packages from emails" do
    before do
      failure = ServiceResult.failure(result: ITSM::EmailThread.new).tap { it.errors.add(:base, :error_unauthorized) }
      service = instance_double(ITSM::InboundEmails::CreateWorkPackageService, call: failure)
      allow(ITSM::InboundEmails::CreateWorkPackageService).to receive(:new).and_return(service)
    end

    it "fails and leaves the email untouched, to be tried again" do
      expect(result.errors.symbols_for(:base)).to eq([:work_package_not_created])
      expect(imap).not_to have_received(:uid_store)
    end
  end

  context "when the work package is rejected with a message" do
    before do
      failure = ServiceResult.failure.tap { it.errors.add(:subject, "Printer of jane@customer.example") }
      service = instance_double(ITSM::InboundEmails::CreateWorkPackageService, call: failure)
      allow(ITSM::InboundEmails::CreateWorkPackageService).to receive(:new).and_return(service)
    end

    it "logs the attribute without the message" do
      result

      expect(warned).to include("Not processed (subject)")
    end
  end

  context "when processing raises" do
    before do
      allow(ITSM::InboundEmails::CreateWorkPackageService).to receive(:new).and_raise(ActiveRecord::StatementInvalid)
      allow(OpenProject.logger).to receive(:error)
    end

    it "marks it as seen and reports the error" do
      expect(result).to be_success
      expect(imap).to have_received(:uid_store).with(7, "+FLAGS", [:Seen])
      expect(OpenProject.logger).to have_received(:error)
        .with("Email 7 failed (ActiveRecord::StatementInvalid)", exception: instance_of(ActiveRecord::StatementInvalid))
    end
  end

  context "when the database is not available" do
    before do
      allow(ITSM::InboundEmails::CreateWorkPackageService).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished)
      allow(OpenProject.logger).to receive(:error)
    end

    it "fails and leaves the email untouched, to be tried again" do
      expect(result.errors.symbols_for(:base)).to eq([:processing_failed])
      expect(imap).not_to have_received(:uid_store)
      expect(OpenProject.logger).to have_received(:error)
        .with("Email 7 not processed (ActiveRecord::ConnectionNotEstablished)",
              exception: instance_of(ActiveRecord::ConnectionNotEstablished))
    end
  end

  context "when the email is larger than allowed" do
    before do
      allow(imap).to receive(:uid_fetch).with(7, "RFC822.SIZE")
        .and_return([Net::IMAP::FetchData.new(7, { "RFC822.SIZE" => 51.megabytes })])
    end

    it "marks it as seen without loading it" do
      expect { result }.not_to change(WorkPackage, :count)
      expect(result).to be_success
      expect(imap).not_to have_received(:uid_fetch).with(7, "BODY.PEEK[]")
      expect(imap).to have_received(:uid_store).with(7, "+FLAGS", [:Seen])
      expect(warned).to include("Not processed (too large)")
    end
  end

  context "when the email is gone" do
    let(:fetched) { nil }

    it "does nothing" do
      expect(result).to be_success
      expect(imap).not_to have_received(:uid_store)
    end
  end

  context "when the connection drops" do
    before { allow(imap).to receive(:uid_fetch).and_raise(Errno::ECONNRESET) }

    it "fails with the reason" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:unreachable])
    end
  end
end
