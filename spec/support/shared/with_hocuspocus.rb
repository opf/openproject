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

# This context allows to run tests against an OpenProject Hocuspocus server,
# either running in Docker or locally.
# It will throw an error if Hocuspocus is not reachable.
RSpec.shared_context "with hocuspocus" do
  include_context "with settings reset"

  before do
    host = ENV["OPENPROJECT_TESTING_WITH_DOCKER"] == "true" ? "hocuspocus-test" : "127.0.0.1"
    port = 1234
    if ENV["OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__URL"].nil?
      Setting.collaborative_editing_hocuspocus_url = "ws://#{host}:#{port}"
    end
    if ENV["OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET"].nil?
      Setting.collaborative_editing_hocuspocus_secret = "secret12345"
    end

    begin
      TCPSocket.new(host, port).close
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError => e
      raise("Hocuspocus server is required for this test. It is not reachable at #{host}:#{port} - #{e.message}")
    end
  end
end
