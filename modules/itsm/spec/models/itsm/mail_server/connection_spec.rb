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

RSpec.describe ITSM::MailServer::Connection do
  subject(:connection) { mail_server.imap_connection.tap { it.assign_attributes(host:, port:, encryption:) } }

  let(:mail_server) { create(:itsm_mail_server) }
  let(:host) { "imap.mailbox.org" }
  let(:port) { 993 }
  let(:encryption) { "tls" }

  it { is_expected.to be_valid }

  it "uses a table named after the mail server" do
    expect(described_class.table_name).to eq("itsm_mail_server_connections")
  end

  it "knows how it is encrypted" do
    expect(connection).to have_attributes(tls?: true, starttls?: false)
  end

  context "without encryption" do
    let(:encryption) { "none" }

    it { is_expected.not_to be_valid }
  end

  context "with an unknown protocol" do
    before { connection.protocol = "pop3" }

    it { is_expected.not_to be_valid }
  end

  context "with an upper case host, surrounding whitespace and a trailing dot" do
    let(:host) { " IMAP.Mailbox.org. " }

    it "normalizes the host" do
      expect(connection.host).to eq("imap.mailbox.org")
    end
  end

  context "with an IPv4 address as host" do
    let(:host) { "192.168.1.10" }

    it { is_expected.not_to be_valid }
  end

  context "with an IPv6 address as host" do
    let(:host) { "::1" }

    it { is_expected.not_to be_valid }
  end

  context "with a host that is not a hostname" do
    let(:host) { "imap.mailbox.org/inbox" }

    it { is_expected.not_to be_valid }
  end

  context "without a host" do
    let(:host) { "" }

    it { is_expected.not_to be_valid }
  end

  context "with a port out of range" do
    let(:port) { 70_000 }

    it { is_expected.not_to be_valid }
  end

  context "when the server already has a connection for the protocol" do
    subject(:connection) { build(:itsm_mail_server_connection, :imap, mail_server:) }

    it { is_expected.not_to be_valid }

    it "is rejected by the database as well" do
      expect { connection.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context "when an incoming mailbox uses it" do
    before { create(:itsm_incoming_mailbox, mail_server:) }

    it "cannot be destroyed" do
      expect(connection.destroy).to be(false)
      expect(described_class).to exist(connection.id)
    end
  end

  context "when it has health reports" do
    let!(:health_report) { HealthReport.create!(subject: connection) }

    it "deletes them together with the connection" do
      connection.destroy

      expect(HealthReport).not_to exist(health_report.id)
    end
  end
end
