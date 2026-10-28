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
  subject(:mail_server) { build(:itsm_mail_server, :imap, name:, host:, port:, encryption:) }

  let(:name) { "Mailbox.org" }
  let(:host) { "imap.mailbox.org" }
  let(:port) { 993 }
  let(:encryption) { "tls" }

  it { is_expected.to be_valid }

  it "knows how it is encrypted" do
    expect(mail_server).to have_attributes(tls?: true, starttls?: false)
  end

  context "without encryption" do
    let(:encryption) { "none" }

    it { is_expected.not_to be_valid }
  end

  context "with an unknown protocol" do
    before { mail_server.protocol = "pop3" }

    it { is_expected.not_to be_valid }
  end

  context "when its protocol is changed after it was saved" do
    before { mail_server.save! }

    it "is rejected" do
      expect { mail_server.protocol = "smtp" }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end

  context "with an upper case host, surrounding whitespace and a trailing dot" do
    let(:host) { " IMAP.Mailbox.org. " }

    it "normalizes the host" do
      expect(mail_server.host).to eq("imap.mailbox.org")
    end
  end

  context "without a host" do
    let(:host) { "" }

    it { is_expected.not_to be_valid }
  end

  context "with a port out of range" do
    let(:port) { 70_000 }

    it { is_expected.not_to be_valid }
  end

  context "with a name longer than 255 characters" do
    let(:name) { "a" * 256 }

    it { is_expected.not_to be_valid }
  end

  context "when another IMAP server uses the same name in a different case" do
    let!(:existing) { create(:itsm_mail_server, :imap, name: "MAILBOX.ORG") }

    it "is not valid" do
      expect(mail_server).not_to be_valid
      expect(mail_server.errors.symbols_for(:name)).to include(:taken)
    end

    it "is rejected by the database as well" do
      expect { mail_server.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context "when an SMTP server uses the same name" do
    let!(:existing) { create(:itsm_mail_server, :smtp, name:) }

    it { is_expected.to be_valid }
  end

  context "when an incoming mailbox uses it" do
    before { create(:itsm_incoming_mailbox, mail_server:) }

    it "cannot be destroyed" do
      expect(mail_server.destroy).to be(false)
      expect(mail_server.errors.symbols_for(:base)).to include(:"restrict_dependent_destroy.has_many")
      expect(described_class).to exist(mail_server.id)
    end
  end

  context "when an outgoing mailbox uses it" do
    subject(:mail_server) { create(:itsm_mail_server, :smtp) }

    before { create(:itsm_outgoing_mailbox, mail_server:) }

    it "cannot be destroyed" do
      expect(mail_server.destroy).to be(false)
      expect(described_class).to exist(mail_server.id)
    end
  end
end
