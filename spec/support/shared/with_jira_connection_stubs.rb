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

RSpec.shared_context "with Jira connection stubs" do
  include_context "with ssrf stubs"

  let(:url) { "https://jira.example.com" }
  let(:administrator) { true }
  let(:server_info) { { "version" => "10.3.0" } }
  let(:json_headers) { { "Content-Type" => "application/json" } }
  let!(:server_info_request) do
    stub_request(:get, "#{url}/rest/api/2/serverInfo")
      .to_return(status: 200, body: server_info.to_json, headers: json_headers)
  end
  let!(:permissions_request) do
    stub_request(:get, "#{url}/rest/api/2/mypermissions")
      .to_return(status: 200,
                 body: { "permissions" => { "ADMINISTER" => { "havePermission" => administrator } } }.to_json,
                 headers: json_headers)
  end
end
