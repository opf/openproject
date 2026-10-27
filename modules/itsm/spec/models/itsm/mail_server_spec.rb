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

RSpec.describe ITSM::MailServer do
  subject(:mail_server) { build(:itsm_mail_server, name:) }

  let(:name) { "Mailbox.org" }

  it { is_expected.to be_valid }

  it "saves its IMAP and SMTP connections with it" do
    mail_server.save!

    expect(mail_server.reload.connections.pluck(:protocol)).to contain_exactly("imap", "smtp")
  end

  context "without an IMAP connection" do
    subject(:mail_server) { build(:itsm_mail_server, imap_connection: nil) }

    it { is_expected.not_to be_valid }
  end

  context "without an SMTP connection" do
    subject(:mail_server) { build(:itsm_mail_server, smtp_connection: nil) }

    it { is_expected.not_to be_valid }
  end

  context "with an invalid connection" do
    before { mail_server.imap_connection.host = "192.168.1.10" }

    it { is_expected.not_to be_valid }
  end

  context "with a name longer than 255 characters" do
    let(:name) { "a" * 256 }

    it { is_expected.not_to be_valid }
  end

  context "when a mail server already exists" do
    let!(:existing) { create(:itsm_mail_server) }

    it "is not valid" do
      expect(mail_server).not_to be_valid
      expect(mail_server.errors.symbols_for(:base)).to include(:mail_server_limit_reached)
    end

    it "keeps the existing server valid" do
      expect(existing).to be_valid
    end
  end

  context "when another server uses the same name in a different case" do
    let!(:existing) { create(:itsm_mail_server, name: "MAILBOX.ORG") }

    it "is not valid" do
      expect(mail_server).not_to be_valid
      expect(mail_server.errors.symbols_for(:name)).to include(:taken)
    end

    it "is rejected by the database as well" do
      expect { mail_server.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context "when it is destroyed" do
    subject(:mail_server) { create(:itsm_mail_server) }

    it "deletes its connections" do
      connection_ids = mail_server.connections.ids

      mail_server.destroy

      expect(ITSM::MailServer::Connection.where(id: connection_ids)).to be_empty
    end
  end

  context "without any mailbox using it" do
    subject(:mail_server) { create(:itsm_mail_server) }

    it { is_expected.not_to be_in_use }
  end

  context "when an incoming mailbox uses the server" do
    subject(:mail_server) { create(:itsm_mail_server) }

    before { create(:itsm_incoming_mailbox, mail_server:) }

    it { is_expected.to be_in_use }

    it "cannot be destroyed" do
      expect(mail_server.destroy).to be(false)
      expect(mail_server.errors.symbols_for(:base)).to include(:"restrict_dependent_destroy.has_many")
      expect(described_class).to exist(mail_server.id)
    end
  end

  context "when an outgoing mailbox uses the server" do
    subject(:mail_server) { create(:itsm_mail_server) }

    before { create(:itsm_outgoing_mailbox, mail_server:) }

    it "cannot be destroyed" do
      expect(mail_server.destroy).to be(false)
      expect(described_class).to exist(mail_server.id)
    end
  end
end
