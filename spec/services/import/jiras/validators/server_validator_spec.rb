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

  subject(:group) { described_class.call(jira) }

  let(:results) { group.results.map { [it.key, it.state, it.code].compact } }

  let(:jira) { build(:jira, url:) }

  def stub_server_info = stub_request(:get, "#{url}/rest/api/2/serverInfo")

  context "when Jira answers with its server info" do
    it "passes every check" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira success],
                             %i[version_supported success], %i[auth_method_supported success]])
    end
  end

  context "when Jira reports its version numbers" do
    let(:server_info) { { "version" => "10.3.0-custom-build", "versionNumbers" => [12, 0, 0] } }

    it "checks the version numbers instead of the version" do
      expect(group[:version_supported])
        .to have_attributes(state: :warning, code: :unsupported_version, context: { version: "12.0.0" })
    end
  end

  context "when Jira reports a version newer than the supported ones" do
    let(:server_info) { { "version" => "12.0.0" } }

    it "warns about the unsupported version and checks the rest" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira success],
                             %i[version_supported warning unsupported_version], %i[auth_method_supported success]])
    end
  end

  context "when Jira reports a version that cannot be read" do
    let(:server_info) { { "version" => "unknown" } }

    it "warns about the unknown version and accepts the authentication method" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira success],
                             %i[version_supported warning unknown_version], %i[auth_method_supported success]])
    end
  end

  context "when Jira 8 is used with a personal access token" do
    let(:server_info) { { "version" => "8.20.30" } }

    it "fails the authentication method check" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira success],
                             %i[version_supported success], %i[auth_method_supported failure basic_auth_required]])
      expect(group[:auth_method_supported].context).to eq(version: "8.20.30")
    end
  end

  context "when Jira 8 is used with basic auth" do
    let(:jira) { build(:jira, :with_basic_auth, url:) }

    let(:server_info) { { "version" => "8.20.30" } }

    it "passes every check" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira success],
                             %i[version_supported success], %i[auth_method_supported success]])
    end
  end

  context "when the server answers with JSON that is not Jira's server info" do
    let(:server_info) { { "status" => "ok" } }

    it "fails the Jira check" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira failure not_jira],
                             %i[version_supported skipped], %i[auth_method_supported skipped]])
    end
  end

  context "when the server answers with something other than JSON" do
    before { stub_server_info.to_return(status: 200, body: "<html></html>") }

    it "fails the Jira check" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira failure invalid_response],
                             %i[version_supported skipped], %i[auth_method_supported skipped]])
    end
  end

  context "when the server has no Jira API" do
    before { stub_server_info.to_return(status: 404) }

    it "fails the Jira check" do
      expect(results).to eq([%i[reachable success], %i[responds_as_jira failure not_found],
                             %i[version_supported skipped], %i[auth_method_supported skipped]])
    end
  end

  context "when Jira answers with a server error" do
    before { stub_server_info.to_return(status: 500) }

    it "fails the Jira check" do
      expect(group[:responds_as_jira])
        .to have_attributes(state: :failure, code: :api_error, context: { status: "500" })
    end
  end

  [401, 403].each do |status|
    context "when Jira rejects the credentials with #{status}" do
      before { stub_server_info.to_return(status:) }

      it "skips the remaining checks without failing" do
        expect(results).to eq([%i[reachable success], %i[responds_as_jira skipped],
                               %i[version_supported skipped], %i[auth_method_supported skipped]])
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
        expect(results).to eq([[:reachable, :failure, code], %i[responds_as_jira skipped],
                               %i[version_supported skipped], %i[auth_method_supported skipped]])
      end
    end
  end
end
