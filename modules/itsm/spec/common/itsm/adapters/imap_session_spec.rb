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

RSpec.describe ITSM::Adapters::ImapSession do
  include_context "with a connected IMAP session"

  subject(:unconnected_session) { described_class.new(connection: imap_connection, auth_strategy: imap_auth_strategy) }

  let(:encryption) { "tls" }
  let(:imap_connection) { build(:itsm_mail_server, :imap, encryption:) }

  it "shows only the connection when inspected" do
    expect(session.inspect).to include("imap.example.com")
    expect(session.inspect).not_to include("support@example.com", "@auth_strategy", "@imap")
  end

  it "does not expose the IMAP connection" do
    expect(session).not_to respond_to(:imap)
  end

  describe "#connect" do
    it "logs in over TLS and opens the inbox" do
      expect(unconnected_session.connect).to eq(Dry::Monads::Success(unconnected_session))

      expect(Net::IMAP).to have_received(:new).with("imap.example.com", port: 993, ssl: true, open_timeout: 10)
      expect(imap).not_to have_received(:starttls)
      expect(imap).to have_received(:login).with("support@example.com", "secret")
      expect(imap).to have_received(:select).with("INBOX")
    end

    context "with STARTTLS" do
      let(:encryption) { "starttls" }

      it "upgrades the connection before logging in" do
        unconnected_session.connect

        expect(Net::IMAP).to have_received(:new).with("imap.example.com", port: 993, ssl: false, open_timeout: 10)
        expect(imap).to have_received(:starttls)
      end
    end

    context "when the host resolves to a private address", with_ssrf_ip_allowlist: [] do
      before { allow(OpenProject::SsrfProtection).to receive(:resolver).and_return(->(_host) { [IPAddr.new("10.0.0.5")] }) }

      it "refuses to connect" do
        expect(unconnected_session.connect.failure.code).to eq(:address_not_allowed)
        expect(Net::IMAP).not_to have_received(:new)
      end
    end

    context "when the host cannot be resolved" do
      before { allow(OpenProject::SsrfProtection).to receive(:resolver).and_return(->(_host) { [] }) }

      it "reports the server as unreachable" do
        expect(unconnected_session.connect.failure.code).to eq(:unreachable)
      end
    end

    context "when the server cannot be reached" do
      before { allow(Net::IMAP).to receive(:new).and_raise(Errno::ECONNREFUSED) }

      it "reports the server as unreachable" do
        expect(unconnected_session.connect.failure.code).to eq(:unreachable)
      end
    end

    context "when the certificate is invalid" do
      before { allow(Net::IMAP).to receive(:new).and_raise(OpenSSL::SSL::SSLError, "certificate verify failed") }

      it "reports the TLS failure" do
        expect(unconnected_session.connect.failure.code).to eq(:tls_failed)
      end
    end

    context "when the login is rejected" do
      before { allow(imap).to receive(:login).and_raise(Net::IMAP::NoResponseError.new(imap_rejection)) }

      it "reports the authentication failure without opening the inbox" do
        expect(unconnected_session.connect.failure.code).to eq(:authentication_failed)
        expect(imap).not_to have_received(:select)
      end
    end

    context "when the inbox cannot be opened" do
      before { allow(imap).to receive(:select).and_raise(Net::IMAP::NoResponseError.new(imap_rejection)) }

      it "reports a server error" do
        expect(unconnected_session.connect.failure.code).to eq(:server_error)
      end
    end
  end

  describe "#request" do
    it "yields the IMAP connection and wraps the value" do
      expect(session.request(source: String) { |connection| connection }).to eq(Dry::Monads::Success(imap))
    end

    it "names the given source when the request fails" do
      result = session.request(source: String) { raise IOError }

      expect(result.failure).to have_attributes(code: :unreachable, source: String)
    end
  end

  describe ".open" do
    it "yields the connected session, returns the block's result and logs out" do
      result = described_class.open(connection: imap_connection, auth_strategy: imap_auth_strategy) { Dry::Monads::Success(:done) }

      expect(result).to eq(Dry::Monads::Success(:done))
      expect(imap).to have_received(:logout)
    end

    it "disconnects even when logging out fails" do
      allow(imap).to receive(:logout).and_raise(IOError)

      described_class.open(connection: imap_connection, auth_strategy: imap_auth_strategy) { Dry::Monads::Success() }

      expect(imap).to have_received(:disconnect)
    end

    it "logs out when the block raises" do
      expect { described_class.open(connection: imap_connection, auth_strategy: imap_auth_strategy) { raise ArgumentError } }
        .to raise_error(ArgumentError)
      expect(imap).to have_received(:logout)
    end

    context "when the server stops responding" do
      let(:silent_server) { TCPServer.new("127.0.0.1", 0) }
      let(:accepted) { Queue.new }
      let(:imap_connection) do
        build(:itsm_mail_server, :imap, host: "127.0.0.1", port: silent_server.addr[1], encryption: "starttls")
      end

      before do
        stub_const("#{described_class}::SESSION_TIMEOUT", 0.2)
        allow(Net::IMAP).to receive(:new).and_call_original
        Thread.new { accepted << silent_server.accept.tap { it.write("* OK ready\r\n") } }
      end

      after do
        accepted.pop(timeout: 1)&.close
        silent_server.close
      end

      it "gives up after the session timeout" do
        result = described_class.open(connection: imap_connection, auth_strategy: imap_auth_strategy) { Dry::Monads::Success() }

        expect(result.failure.code).to eq(:timeout)
      end
    end

    context "when connecting fails" do
      before { allow(imap).to receive(:login).and_raise(Net::IMAP::NoResponseError.new(imap_rejection)) }

      it "returns the failure without yielding and logs out" do
        yielded = false

        result = described_class.open(connection: imap_connection, auth_strategy: imap_auth_strategy) { yielded = true }

        expect(result.failure.code).to eq(:authentication_failed)
        expect(yielded).to be(false)
        expect(imap).to have_received(:logout)
      end
    end
  end
end
