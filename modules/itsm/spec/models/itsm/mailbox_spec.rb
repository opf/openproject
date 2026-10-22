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

RSpec.describe ITSM::Mailbox do
  subject(:mailbox) do
    build(:itsm_mailbox, mail_server:, project:, email:, aliases:,
                         imap_username:, imap_password:, smtp_username:, smtp_password:)
  end

  let(:mail_server) { create(:itsm_mail_server) }
  let(:project) { create(:project) }
  let(:email) { "support@example.com" }
  let(:aliases) { [] }
  let(:imap_username) { "support@example.com" }
  let(:imap_password) { "imap-password" }
  let(:smtp_username) { "relay-user" }
  let(:smtp_password) { "smtp-password" }

  it "uses the module table prefix" do
    expect(described_class.table_name).to eq("itsm_mailboxes")
  end

  it { is_expected.to be_valid }

  it "hides the passwords when inspected" do
    expect(mailbox.inspect).not_to include("imap-password", "smtp-password")
  end

  it "exposes the IMAP credentials" do
    expect(mailbox.imap_credentials).to have_attributes(username: "support@example.com", password: "imap-password")
  end

  it "exposes the SMTP credentials" do
    expect(mailbox.smtp_credentials).to have_attributes(username: "relay-user", password: "smtp-password")
  end

  it "hides the password when the credentials are printed" do
    credentials = mailbox.imap_credentials

    expect([credentials.inspect, credentials.to_s, credentials.pretty_inspect].join).not_to include("imap-password")
  end

  context "without an IMAP username" do
    let(:imap_username) { "" }

    it { is_expected.not_to be_valid }
  end

  context "without an SMTP username" do
    let(:smtp_username) { "" }

    it { is_expected.not_to be_valid }
  end

  context "without an IMAP password" do
    let(:imap_password) { nil }

    it { is_expected.not_to be_valid }
  end

  context "without an SMTP password" do
    let(:smtp_password) { nil }

    it { is_expected.not_to be_valid }
  end

  context "with aliases" do
    let(:aliases) { [" Help@Example.com ", "", "help@example.com", "billing@example.com"] }

    it "normalizes them" do
      expect(mailbox.aliases).to eq(%w[help@example.com billing@example.com])
    end

    it "knows all of its addresses" do
      expect(mailbox.known_addresses).to eq(%w[support@example.com help@example.com billing@example.com])
    end
  end

  context "with an invalid alias" do
    let(:aliases) { ["not-an-email"] }

    it { is_expected.not_to be_valid }
  end

  context "when an alias is another mailbox's email" do
    let!(:existing) { create(:itsm_mailbox, email: "help@example.com") }
    let(:aliases) { ["help@example.com"] }

    it { is_expected.not_to be_valid }
  end

  context "when an alias is another mailbox's alias" do
    let!(:existing) { create(:itsm_mailbox, aliases: ["help@example.com"]) }
    let(:aliases) { ["help@example.com"] }

    it { is_expected.not_to be_valid }
  end

  context "when the email is another mailbox's alias" do
    let!(:existing) { create(:itsm_mailbox, aliases: ["support@example.com"]) }

    it { is_expected.not_to be_valid }
  end

  context "when the mailbox is saved again with its own aliases" do
    let(:aliases) { ["help@example.com"] }

    it "does not conflict with itself" do
      mailbox.save!

      expect(mailbox.reload).to be_valid
    end
  end

  context "with surrounding whitespace and upper case letters" do
    let(:email) { "  Support@Example.COM " }

    it "normalizes the email" do
      expect(mailbox.email).to eq("support@example.com")
    end
  end

  context "with an invalid email" do
    let(:email) { "not-an-email" }

    it { is_expected.not_to be_valid }
  end

  context "when another mailbox uses the same email in a different case" do
    let!(:existing) { create(:itsm_mailbox, email: "SUPPORT@example.com") }

    it { is_expected.not_to be_valid }
  end

  context "when another mailbox logs into the same IMAP server with the same username" do
    let!(:existing) { create(:itsm_mailbox, mail_server:, imap_username: "SUPPORT@example.com") }
    let(:email) { "support+demo@example.com" }

    it { is_expected.not_to be_valid }
  end

  context "when another mailbox uses the same IMAP username on a different server" do
    let!(:existing) { create(:itsm_mailbox, imap_username:) }
    let(:email) { "support+demo@example.com" }

    it { is_expected.to be_valid }
  end

  context "without a project" do
    let(:project) { nil }

    it { is_expected.not_to be_valid }
  end

  context "without a mail server" do
    let(:mail_server) { nil }

    it { is_expected.not_to be_valid }
  end

  context "when its project is deleted" do
    let!(:unthreaded_message) { create(:itsm_email_message, mailbox:, thread: nil) }

    it "is deleted together with the project" do
      project.destroy

      expect(described_class).not_to exist(mailbox.id)
    end

    it "deletes the messages that did not lead to a work package" do
      project.destroy

      expect(ITSM::EmailMessage).not_to exist(unthreaded_message.id)
    end
  end

  context "when it is destroyed" do
    let!(:threaded_message) { create(:itsm_email_message, mailbox:) }
    let!(:unthreaded_message) { create(:itsm_email_message, mailbox:, thread: nil) }

    it "deletes the messages that did not lead to a work package" do
      mailbox.destroy

      expect(ITSM::EmailMessage).not_to exist(unthreaded_message.id)
    end

    it "keeps the messages of work package threads" do
      mailbox.destroy

      expect(threaded_message.reload.mailbox).to be_nil
    end
  end
end
