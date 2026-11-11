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

RSpec.describe ITSM::IncomingMailbox do
  subject(:mailbox) { build(:itsm_incoming_mailbox, mail_server:, project:, email:, aliases:, username:, password:) }

  let(:mail_server) { create(:itsm_mail_server, :imap) }
  let(:project) { create(:project) }
  let(:email) { "support@example.com" }
  let(:aliases) { [] }
  let(:username) { "support@example.com" }
  let(:password) { "imap-password" }

  it "uses the module table prefix" do
    expect(described_class.table_name).to eq("itsm_incoming_mailboxes")
  end

  it { is_expected.to be_valid }

  it "hides the password when inspected" do
    expect(mailbox.inspect).not_to include("imap-password")
  end

  context "without a username" do
    let(:username) { "" }

    it { is_expected.not_to be_valid }
  end

  context "with surrounding whitespace in the username" do
    let(:username) { " support@example.com " }

    it "strips it" do
      expect(mailbox.username).to eq("support@example.com")
    end
  end

  context "without a password" do
    let(:password) { nil }

    it { is_expected.not_to be_valid }
  end

  context "without a mail server" do
    let(:mail_server) { nil }

    it { is_expected.not_to be_valid }
  end

  context "with an SMTP server" do
    let(:mail_server) { create(:itsm_mail_server, :smtp) }

    it "is not valid" do
      expect(mailbox).not_to be_valid
      expect(mailbox.errors.symbols_for(:mail_server)).to include(:invalid)
    end
  end

  context "with aliases" do
    let(:aliases) { [" Help@Example.com ", "", nil, "help@example.com", "billing@example.com"] }

    it "normalizes them" do
      expect(mailbox.aliases).to eq(%w[help@example.com billing@example.com])
    end
  end

  context "with surrounding whitespace and upper case letters" do
    let(:email) { "  Support@Example.COM " }

    it "normalizes the email" do
      expect(mailbox.email).to eq("support@example.com")
    end
  end

  context "when another mailbox uses the same email in a different case" do
    let!(:existing) { create(:itsm_incoming_mailbox, email: "SUPPORT@example.com") }

    it { is_expected.not_to be_valid }
  end

  context "when another mailbox logs in to the same server with the same username" do
    let!(:existing) { create(:itsm_incoming_mailbox, mail_server:, username: "SUPPORT@example.com") }
    let(:email) { "support+demo@example.com" }

    it { is_expected.not_to be_valid }

    it "is rejected by the database as well" do
      expect { mailbox.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context "when another mailbox uses the same username on a different server" do
    let!(:existing) { create(:itsm_incoming_mailbox, username:) }
    let(:email) { "support+demo@example.com" }

    it { is_expected.to be_valid }
  end

  context "without a project" do
    let(:project) { nil }

    it { is_expected.not_to be_valid }
  end

  context "when its project is deleted" do
    before { mailbox.save! }

    it "is deleted together with the project" do
      project.destroy

      expect(described_class).not_to exist(mailbox.id)
    end
  end
end
