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

require "webrick"
require "httpx"

RSpec.describe "HTTPX" do
  describe "persistent connections" do
    it "does not hang forever when used to request HTTP 1.1 server" do
      server = WEBrick::HTTPServer.new(
        Port: 0,
        Logger: WEBrick::Log.new(StringIO.new),
        AccessLog: []
      )
      server.mount_proc "/" do |_req, res|
        res.body = "Response Body"
      end
      port = server.listeners[0].addr[1]

      Thread.new { server.start }
      session = HTTPX.plugin(:persistent).with(timeout: { keep_alive_timeout: 2 })
      number_of_requests_made = 0
      begin
        Timeout.timeout(10) do
          session.post("http://localhost:#{port}").raise_for_status
          number_of_requests_made += 1
          sleep 4
          session.post("http://localhost:#{port}").raise_for_status
          number_of_requests_made += 1
        end
      ensure
        expect(number_of_requests_made).to eq(2)
        server.shutdown
      end
    end
  end
end
