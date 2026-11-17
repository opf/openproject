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

RSpec.describe ITSM::OutgoingMailbox do
  subject(:mailbox) { build(:itsm_outgoing_mailbox, mail_server:, project:, sender_email:, username:, password:) }

  let(:mail_server) { create(:itsm_mail_server, :smtp) }
  let(:project) { create(:project) }
  let(:sender_email) { "support@example.com" }
  let(:username) { "relay-user" }
  let(:password) { "smtp-password" }

  it "uses the module table prefix" do
    expect(described_class.table_name).to eq("itsm_outgoing_mailboxes")
  end

  it { is_expected.to be_valid }

  it "hides the password when inspected" do
    expect(mailbox.inspect).not_to include("smtp-password")
  end

  context "without a username" do
    let(:username) { "" }

    it { is_expected.not_to be_valid }
  end

  context "without a password" do
    let(:password) { nil }

    it { is_expected.not_to be_valid }
  end

  context "without a mail server" do
    let(:mail_server) { nil }

    it { is_expected.not_to be_valid }
  end

  context "with an IMAP server" do
    let(:mail_server) { create(:itsm_mail_server, :imap) }

    it "is not valid" do
      expect(mailbox).not_to be_valid
      expect(mailbox.errors.symbols_for(:mail_server)).to include(:invalid)
    end
  end

  context "without a sender email" do
    let(:sender_email) { "" }

    it { is_expected.not_to be_valid }
  end

  context "with a sender email in mixed case and surrounding whitespace" do
    let(:sender_email) { " Support@Example.COM " }

    it "normalizes it" do
      expect(mailbox.sender_email).to eq("support@example.com")
    end
  end

  context "when another project sends with the same account and address" do
    before { create(:itsm_outgoing_mailbox, mail_server:, username:, sender_email:) }

    it "is valid, as projects can share a relay account" do
      expect(mailbox).to be_valid
    end
  end

  context "when its project is deleted" do
    before { mailbox.save! }

    it "is deleted together with the project" do
      project.destroy

      expect(described_class).not_to exist(mailbox.id)
    end
  end
end
