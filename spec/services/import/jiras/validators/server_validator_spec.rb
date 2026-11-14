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

RSpec.describe Import::Jiras::Validators::ServerValidator, :webmock do
  include_context "with Jira connection stubs"

  subject(:results) { described_class.call(jira).results.map { [it.key, it.state, it.code].compact } }

  let(:jira) { build(:jira, url:) }

  def stub_server_info = stub_request(:get, "#{url}/rest/api/2/serverInfo")

  context "when Jira answers with its server info" do
    it "passes every check" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira success]])
    end
  end

  context "when the server answers with JSON that is not Jira's server info" do
    before { stub_server_info.to_return(status: 200, body: { "status" => "ok" }.to_json, headers: json_headers) }

    it "fails the Jira check" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira failure not_jira]])
    end
  end

  context "when the server answers with something other than JSON" do
    before { stub_server_info.to_return(status: 200, body: "<html></html>") }

    it "fails the Jira check" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira failure invalid_response]])
    end
  end

  context "when the server has no Jira API" do
    before { stub_server_info.to_return(status: 404) }

    it "fails the Jira check" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira failure not_found]])
    end
  end

  context "when Jira answers with a server error" do
    before { stub_server_info.to_return(status: 500) }

    it "fails the Jira check" do
      expect(described_class.call(jira)[:responds_as_jira])
        .to have_attributes(state: :failure, code: :api_error, context: { status: "500" })
    end
  end

  [401, 403].each do |status|
    context "when Jira rejects the credentials with #{status}" do
      before { stub_server_info.to_return(status:) }

      it "skips the Jira check without failing" do
        expect(results).to eq([%i[reachable success], %i[responds_as_jira skipped]])
      end
    end
  end

  {
    SsrfFilter::PrivateIPAddress => :ssrf_blocked,
    OpenSSL::SSL::SSLError => :ssl_error,
    Net::OpenTimeout => :timeout,
    Errno::ETIMEDOUT => :timeout,
    Errno::ECONNREFUSED => :unreachable,
    Errno::ECONNRESET => :unreachable,
    EOFError => :unreachable,
    Net::HTTPBadResponse => :unreachable
  }.each do |error, code|
    context "when the connection fails with #{error}" do
      before { stub_server_info.to_raise(error) }

      it "fails the reachable check with #{code}" do
        expect(results).to eq([[:reachable, :failure, code], %i[responds_as_jira skipped]])
      end
    end
  end
end
