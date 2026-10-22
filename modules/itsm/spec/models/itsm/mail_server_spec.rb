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
  subject(:mail_server) do
    build(:itsm_mail_server, name:, imap_host:, imap_port:, imap_encryption:, smtp_host:, smtp_encryption:)
  end

  let(:name) { "Mailbox.org" }
  let(:imap_host) { "imap.mailbox.org" }
  let(:imap_port) { 993 }
  let(:imap_encryption) { "tls" }
  let(:smtp_host) { "smtp.mailbox.org" }
  let(:smtp_encryption) { "starttls" }

  it { is_expected.to be_valid }

  it "exposes the IMAP connection" do
    expect(mail_server.imap).to eq(ITSM::MailServer::Connection.new(host: "imap.mailbox.org", port: 993, encryption: "tls"))
  end

  it "exposes the SMTP connection" do
    expect(mail_server.smtp).to have_attributes(host: "smtp.mailbox.org", port: 587, encryption: "starttls")
  end

  it "knows how each connection is encrypted" do
    expect([mail_server.imap.tls?, mail_server.smtp.starttls?]).to eq([true, true])
  end

  context "without IMAP encryption" do
    let(:imap_encryption) { "none" }

    it { is_expected.not_to be_valid }
  end

  context "without SMTP encryption" do
    let(:smtp_encryption) { "none" }

    it { is_expected.not_to be_valid }
  end

  context "with upper case hosts and surrounding whitespace" do
    let(:imap_host) { " IMAP.Mailbox.org " }
    let(:smtp_host) { "SMTP.mailbox.org " }

    it "normalizes both hosts" do
      expect([mail_server.imap_host, mail_server.smtp_host]).to eq(%w[imap.mailbox.org smtp.mailbox.org])
    end
  end

  context "with an IPv4 address as IMAP host" do
    let(:imap_host) { "192.168.1.10" }

    it { is_expected.not_to be_valid }
  end

  context "with an IPv6 address as SMTP host" do
    let(:smtp_host) { "::1" }

    it { is_expected.not_to be_valid }
  end

  context "with an IMAP host that is not a hostname" do
    let(:imap_host) { "imap.mailbox.org/inbox" }

    it { is_expected.not_to be_valid }
  end

  context "without an SMTP host" do
    let(:smtp_host) { "" }

    it { is_expected.not_to be_valid }
  end

  context "with an IMAP port out of range" do
    let(:imap_port) { 70_000 }

    it { is_expected.not_to be_valid }
  end

  context "with a name longer than 255 characters" do
    let(:name) { "a" * 256 }

    it { is_expected.not_to be_valid }
  end

  context "when another server uses the same name in a different case" do
    let!(:existing) { create(:itsm_mail_server, name: "MAILBOX.ORG") }

    it { is_expected.not_to be_valid }

    it "is rejected by the database as well" do
      expect { mail_server.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context "when a mailbox uses the server" do
    let!(:mailbox) { create(:itsm_mailbox, mail_server:) }

    it "cannot be destroyed" do
      expect(mail_server.destroy).to be(false)
      expect(described_class).to exist(mail_server.id)
    end
  end

  context "when it has health reports" do
    let!(:health_report) { HealthReport.create!(subject: mail_server) }

    it "deletes them together with the server" do
      mail_server.destroy

      expect(HealthReport).not_to exist(health_report.id)
    end
  end
end
