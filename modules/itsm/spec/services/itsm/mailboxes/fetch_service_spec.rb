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

RSpec.describe ITSM::Mailboxes::FetchService, with_flag: { helpdesk: true } do
  subject(:result) { described_class.new(model: mailbox).call }

  let(:mailbox) { create(:itsm_mailbox, active:, consecutive_failures:, last_error:) }
  let(:active) { true }
  let(:consecutive_failures) { 0 }
  let(:last_error) { nil }
  let(:imap) do
    instance_double(Net::IMAP, login: nil, select: nil, uid_store: nil, uid_expunge: nil, capable?: true,
                               logout: nil, disconnect: nil, disconnected?: false)
  end
  let(:unseen_uids) { [2, 1] }
  let(:emails) do
    {
      1 => "Message-ID: <first@customer.example>\r\nFrom: jane@customer.example\r\nSubject: First\r\n\r\nHello",
      2 => "Message-ID: <second@customer.example>\r\nSubject: No sender\r\n\r\nHello"
    }
  end

  before do
    allow(OpenProject::SsrfProtection).to receive(:resolver).and_return(->(_host) { [IPAddr.new("203.0.113.10")] })
    allow(Net::IMAP).to receive(:new).and_return(imap)
    allow(imap).to receive(:uid_search).and_return(unseen_uids)
    allow(imap).to receive(:uid_fetch) do |uid, _attr|
      emails[uid] && [Net::IMAP::FetchData.new(uid, { "BODY[]" => emails[uid] })]
    end
  end

  it "logs in with the mailbox's IMAP settings" do
    result

    expect(Net::IMAP).to have_received(:new).with(mailbox.mail_server.imap_host, port: 993, ssl: true, open_timeout: 10)
    expect(imap).to have_received(:login).with(mailbox.imap_username, "imap-password")
  end

  it "stores new emails and removes them from the server" do
    expect(result).to be_success
    expect(mailbox.messages.pluck(:message_id, :status)).to eq([%w[first@customer.example received]])
    expect(imap).to have_received(:uid_store).with(1, "+FLAGS", [:Deleted])
    expect(imap).to have_received(:uid_expunge).with(1)
  end

  it "marks emails that could not be stored as seen and leaves them on the server" do
    result

    expect(imap).to have_received(:uid_store).with(2, "+FLAGS", [:Seen])
    expect(imap).not_to have_received(:uid_store).with(2, "+FLAGS", [:Deleted])
  end

  it "logs out afterwards" do
    result

    expect(imap).to have_received(:logout)
  end

  context "when processing an email raises" do
    before do
      allow(ITSM::InboundEmail).to receive(:new).and_call_original
      allow(ITSM::InboundEmail).to receive(:new).with(emails[1]).and_raise(ArgumentError)
    end

    it "marks it as seen and continues with the next one" do
      expect(result).to be_success
      expect(imap).to have_received(:uid_store).with(1, "+FLAGS", [:Seen])
      expect(imap).to have_received(:uid_fetch).with(2, "BODY.PEEK[]")
    end
  end

  context "when an email was stored in an earlier run that did not get to remove it" do
    before { create(:itsm_email_message, mailbox:, thread: nil, message_id: "first@customer.example") }

    it "removes it from the server without storing it again" do
      expect { result }.not_to change(ITSM::EmailMessage, :count)
      expect(imap).to have_received(:uid_store).with(1, "+FLAGS", [:Deleted])
    end
  end

  context "when the database fails while storing an email" do
    before { allow(ITSM::EmailMessages::CreateService).to receive(:new).and_raise(ActiveRecord::ConnectionNotEstablished) }

    it "aborts the run without marking any email as read" do
      expect { result }.to raise_error(ActiveRecord::ConnectionNotEstablished)
      expect(imap).not_to have_received(:uid_store)
      expect(imap).to have_received(:logout)
    end
  end

  context "when an email disappears before it is fetched" do
    before { emails.delete(1) }

    it "leaves it alone" do
      expect(result).to be_success
      expect(imap).not_to have_received(:uid_store).with(1, any_args)
    end
  end

  it "records the successful check", :freeze_time do
    result

    expect(mailbox.reload).to have_attributes(last_fetched_at: Time.current,
                                              next_fetch_at: 15.minutes.from_now,
                                              consecutive_failures: 0,
                                              last_error: nil)
  end

  context "with earlier failures" do
    let(:consecutive_failures) { 3 }
    let(:last_error) { "unreachable" }

    it "resets the failure state" do
      result

      expect(mailbox.reload).to have_attributes(consecutive_failures: 0, last_error: nil)
    end
  end

  context "when the server cannot be reached", :freeze_time do
    before { allow(Net::IMAP).to receive(:new).and_raise(Errno::ECONNREFUSED) }

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

  context "when the connection drops in the middle of the run" do
    before { allow(imap).to receive(:uid_store).with(1, "+FLAGS", [:Deleted]).and_raise(IOError) }

    it "stops and records the failure" do
      expect(result.errors.symbols_for(:base)).to eq([:unreachable])
      expect(imap).not_to have_received(:uid_fetch).with(2, anything)
      expect(imap).to have_received(:logout)
    end
  end

  context "when the mailbox is paused" do
    let(:active) { false }

    it "does not connect" do
      expect(result).to be_failure
      expect(Net::IMAP).not_to have_received(:new)
    end
  end

  context "when the mailbox is already being checked" do
    before do
      allow(OpenProject::Mutex).to receive(:with_advisory_lock)
        .with(ITSM::Mailbox, "itsm_mailbox_fetch_#{mailbox.id}", timeout_seconds: 0)
        .and_return(false)
    end

    it "does not connect" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:base)).to eq([:fetch_in_progress])
      expect(Net::IMAP).not_to have_received(:new)
    end
  end
end
