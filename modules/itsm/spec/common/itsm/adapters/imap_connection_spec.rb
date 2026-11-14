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

RSpec.describe ITSM::Adapters::ImapConnection do
  subject(:connection) do
    described_class.new("imap.example.com", addresses:, port: 993, ssl: false, open_timeout: 1)
  end

  let(:addresses) { %w[2001:db8::1 203.0.113.10] }
  let(:sockets) { UNIXSocket.pair }
  let(:client) { sockets.first }
  let(:server) { sockets.last }

  before do
    allow(Socket).to receive(:tcp).with("2001:db8::1", 993, connect_timeout: 1).and_raise(Errno::ENETUNREACH)
    allow(Socket).to receive(:tcp).with("203.0.113.10", 993, connect_timeout: 1).and_return(client)
  end

  after { sockets.each(&:close) }

  context "when the server greets" do
    before do
      server.write("* OK ready\r\n")
      allow(client).to receive(:timeout=).and_call_original
    end

    after { connection.disconnect }

    it "connects to the next checked address when one cannot be reached, without resolving the host" do
      expect(connection.greeting.data.text).to eq("ready")
      expect(connection.host).to eq("imap.example.com")
      expect(Socket).to have_received(:tcp).twice
    end

    it "logs the address it could not reach" do
      warnings = []
      allow(Rails.logger).to receive(:warn) { |&message| warnings << message.call }

      connection

      expect(warnings).to eq(["Connecting to 2001:db8::1 failed (Errno::ENETUNREACH), trying the next address"])
    end

    it "limits only the wait for the greeting" do
      connection

      expect(client).to have_received(:timeout=).with(1).ordered
      expect(client).to have_received(:timeout=).with(nil).ordered
      expect(client.timeout).to be_nil
    end
  end

  context "when the server never greets" do
    it "gives up after the open timeout" do
      expect { connection }.to raise_error(IO::TimeoutError)
    end
  end

  context "when no checked address can be reached" do
    before { allow(Socket).to receive(:tcp).with("203.0.113.10", 993, connect_timeout: 1).and_raise(Errno::ECONNREFUSED) }

    it "raises the error of the last address" do
      expect { connection }.to raise_error(Errno::ECONNREFUSED)
      expect(Socket).to have_received(:tcp).twice
    end
  end
end
