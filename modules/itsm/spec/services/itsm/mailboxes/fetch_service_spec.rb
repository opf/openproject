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

RSpec.describe ITSM::Mailboxes::FetchService, with_flag: { helpdesk: true }, with_settings: { helpdesk_enabled: true } do
  subject(:result) { described_class.new(mailbox).call }

  let(:mailbox) { create(:itsm_incoming_mailbox, active:, consecutive_failures:, last_error:) }
  let(:active) { true }
  let(:consecutive_failures) { 0 }
  let(:last_error) { nil }
  let(:imap) { instance_double(Net::IMAP, login: nil, select: nil, logout: nil, disconnect: nil, disconnected?: false) }
  let(:unseen_uids) { [2, 1] }
  let(:process_email_service) { instance_double(ITSM::Mailboxes::ProcessEmailService, call: ServiceResult.success(result: mailbox)) }

  before do
    with_ssrf_ip_allowlist(["203.0.113.10"])
    allow(OpenProject::SsrfProtection).to receive(:resolver).and_return(->(_host) { [IPAddr.new("203.0.113.10")] })
    allow(ITSM::Adapters::ImapConnection).to receive(:new).and_return(imap)
    allow(imap).to receive(:uid_search).and_return(unseen_uids)
    allow(ITSM::Mailboxes::ProcessEmailService).to receive(:new)
      .with(mailbox:, session: instance_of(ITSM::Adapters::ImapSession))
      .and_return(process_email_service)
  end

  it "logs in with the mailbox's IMAP settings" do
    result

    expect(ITSM::Adapters::ImapConnection).to have_received(:new)
      .with(mailbox.mail_server.host,
            addresses: ["203.0.113.10"],
            port: 993,
            ssl: { min_version: OpenSSL::SSL::TLS1_2_VERSION },
            open_timeout: 10)
    expect(imap).to have_received(:login).with(mailbox.username, "imap-password")
  end

  it "processes the unseen emails, oldest first" do
    expect(result).to be_success
    expect(process_email_service).to have_received(:call).with(uid: 1).ordered
    expect(process_email_service).to have_received(:call).with(uid: 2).ordered
  end

  it "logs out afterwards" do
    result

    expect(imap).to have_received(:logout)
  end

  it "does not schedule another check" do
    expect { result }.not_to have_enqueued_job(ITSM::Mailboxes::FetchJob)
  end

  it "records the successful check", freeze_time: Time.current.change(usec: 0) do
    result

    expect(mailbox.reload).to have_attributes(last_fetched_at: Time.current,
                                              next_fetch_at: nil,
                                              consecutive_failures: 0,
                                              last_error: nil)
  end

  context "with a new email on the server" do
    let(:mailbox) { create(:itsm_incoming_mailbox, project: create(:project_with_types)) }
    let(:unseen_uids) { [1] }
    let(:raw) { Mail.new(message_id: "<request-1@customer.example>", from: "jane@customer.example", body: "Hello").to_s }
    let!(:status) { create(:default_status) }
    let!(:priority) { create(:default_priority) }

    before do
      allow(ITSM::Mailboxes::ProcessEmailService).to receive(:new).and_call_original
      allow(imap).to receive_messages(uid_fetch: [Net::IMAP::FetchData.new(1, { "BODY[]" => raw })],
                                      uid_store: nil, uid_expunge: nil, capable?: true)
    end

    it "creates a work package and removes the email from the server" do
      expect { result }.to change { WorkPackage.where(project: mailbox.project).count }.by(1)
      expect(imap).to have_received(:uid_store).with(1, "+FLAGS", [:Deleted])
      expect(imap).to have_received(:uid_expunge).with(1)
    end
  end

  context "with more unseen emails than one run reads" do
    before { stub_const("#{described_class}::BATCH_SIZE", 1) }

    it "processes only the oldest ones" do
      result

      expect(process_email_service).to have_received(:call).once.with(uid: 1)
    end

    it "checks the mailbox again right away" do
      expect { result }.to have_enqueued_job(ITSM::Mailboxes::FetchJob).with(mailbox)
    end
  end

  context "with earlier failures" do
    let(:consecutive_failures) { 3 }
    let(:last_error) { "unreachable" }

    it "resets the failure state" do
      result

      expect(mailbox.reload).to have_attributes(consecutive_failures: 0, last_error: nil)
    end
  end

  context "when the server cannot be reached", freeze_time: Time.current.change(usec: 0) do
    let(:warnings) { [] }

    before do
      allow(ITSM::Adapters::ImapConnection).to receive(:new).and_raise(Errno::ECONNREFUSED)
      allow(Rails.logger).to receive(:warn) { |&message| warnings << message.call }
    end

    it "logs the server and the error" do
      result

      expect(warnings).to include("Fetching from #{mailbox.mail_server.host}:993 failed (unreachable): Connection refused")
    end

    it "fails with the reason" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:unreachable])
    end

    it "records the failure and retries later" do
      result

      expect(mailbox.reload).to have_attributes(consecutive_failures: 1,
                                                last_error: "unreachable",
                                                next_fetch_at: 30.minutes.from_now,
                                                last_fetched_at: nil)
    end
  end

  context "when no work package can be created from an email" do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 2)
      allow(process_email_service).to receive(:call).with(uid: 1)
        .and_return(ServiceResult.failure(result: mailbox).tap { it.errors.add(:base, :work_package_not_created) })
    end

    it "stops, so the email and the ones after it are tried again later" do
      expect { result }.not_to have_enqueued_job(ITSM::Mailboxes::FetchJob)
      expect(result.errors.symbols_for(:base)).to eq([:work_package_not_created])
      expect(mailbox.reload).to have_attributes(last_error: "work_package_not_created", consecutive_failures: 1)
      expect(process_email_service).not_to have_received(:call).with(uid: 2)
    end
  end

  context "when the connection drops in the middle of the run" do
    before do
      allow(process_email_service).to receive(:call).with(uid: 1)
        .and_return(ServiceResult.failure(result: mailbox).tap { it.errors.add(:base, :unreachable) })
    end

    it "stops and records the failure" do
      expect(result.errors.symbols_for(:base)).to eq([:unreachable])
      expect(mailbox.reload.last_error).to eq("unreachable")
      expect(process_email_service).not_to have_received(:call).with(uid: 2)
      expect(imap).to have_received(:logout)
    end
  end

  context "when the mailbox is paused" do
    let(:active) { false }

    it "does not connect" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:inactive])
      expect(ITSM::Adapters::ImapConnection).not_to have_received(:new)
    end
  end

  context "when the help desk is turned off in the administration", with_settings: { helpdesk_enabled: false } do
    it "does not connect" do
      expect(result.errors.symbols_for(:base)).to eq([:inactive])
      expect(ITSM::Adapters::ImapConnection).not_to have_received(:new)
    end
  end

  context "with the help desk feature disabled", with_flag: { helpdesk: false } do
    it "does not connect" do
      expect(result.errors.symbols_for(:base)).to eq([:inactive])
      expect(ITSM::Adapters::ImapConnection).not_to have_received(:new)
    end
  end

  context "when the project no longer uses the help desk" do
    let(:mailbox) { create(:itsm_incoming_mailbox, project: create(:project, disable_modules: :helpdesk)) }

    it "does not connect" do
      expect(result.errors.symbols_for(:base)).to eq([:inactive])
      expect(ITSM::Adapters::ImapConnection).not_to have_received(:new)
    end
  end

  context "when the mailbox is already being checked" do
    before do
      allow(OpenProject::Mutex).to receive(:with_advisory_lock)
        .with(ITSM::IncomingMailbox, "itsm_mailbox_fetch_#{mailbox.id}", timeout_seconds: 0)
        .and_return(false)
    end

    it "does not connect" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:fetch_in_progress])
      expect(ITSM::Adapters::ImapConnection).not_to have_received(:new)
    end
  end
end
