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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::Dev::CableTunnel do
  subject(:tunnel) { described_class.new(app, target: URI("http://127.0.0.1:#{upstream.addr[1]}")) }

  let(:app) { ->(_env) { [200, {}, ["app"]] } }
  let(:upstream) { TCPServer.new("127.0.0.1", 0) }
  let(:client_sockets) { UNIXSocket.pair }
  let(:env) do
    Rack::MockRequest.env_for("/cable?jid=1", "HTTP_UPGRADE" => "websocket", "HTTP_COOKIE" => "session=abc")
      .merge("rack.hijack?" => true, "rack.hijack" => -> { client_sockets.first })
  end

  after do
    upstream.close
    client_sockets.each(&:close)
  end

  it "passes other paths to the app" do
    expect(tunnel.call(env.merge("PATH_INFO" => "/projects"))).to eq([200, {}, ["app"]])
  end

  it "forwards the request to anycable-go and streams the hijacked socket" do
    expect(tunnel.call(env).first).to eq(-1)

    connection = upstream.accept
    head = connection.readpartial(4096)
    expect(head).to start_with("GET /cable?jid=1 HTTP/1.1\r\n")
    expect(head).to include("UPGRADE: websocket\r\n", "COOKIE: session=abc\r\n")

    connection.write("HTTP/1.1 101 Switching Protocols\r\n\r\n")
    expect(client_sockets.last.readpartial(4096)).to eq("HTTP/1.1 101 Switching Protocols\r\n\r\n")
    connection.close
  end

  it "answers with 502 when anycable-go is not running" do
    port = upstream.addr[1]
    upstream.close
    unreachable = described_class.new(app, target: URI("http://127.0.0.1:#{port}"))

    expect(unreachable.call(env).first).to eq(502)
  end
end
