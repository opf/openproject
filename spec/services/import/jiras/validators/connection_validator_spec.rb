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

RSpec.describe Import::Jiras::Validators::ConnectionValidator, :webmock do
  include_context "with Jira connection stubs"

  subject(:report) { described_class.new(jira).call }

  let(:jira) { create(:jira, url:) }

  context "with a working connection" do
    it "runs every group and passes" do
      expect(report.results.map(&:key)).to eq(%i[configuration server authorization])
      expect(report).to be_healthy
    end

    it "does not store the report" do
      expect(report).not_to be_persisted
    end
  end

  context "when the configuration is incomplete" do
    let(:jira) { build(:jira, url:, personal_access_token: nil) }

    it "stops before asking Jira" do
      expect(report.results.map(&:key)).to eq(%i[configuration])
      expect(server_info_request).not_to have_been_requested
    end
  end

  context "when Jira cannot be reached" do
    before { stub_request(:get, "#{url}/rest/api/2/serverInfo").to_raise(Errno::ECONNREFUSED) }

    it "stops before checking the authorization" do
      expect(report.results.map(&:key)).to eq(%i[configuration server])
      expect(permissions_request).not_to have_been_requested
    end
  end

  context "when Jira rejects the credentials on both requests, like Jira 10" do
    before do
      stub_request(:get, "#{url}/rest/api/2/serverInfo").to_return(status: 401)
      stub_request(:get, "#{url}/rest/api/2/mypermissions").to_return(status: 401)
    end

    it "reports the rejected credentials in the authorization group" do
      expect(report.group(:server)[:responds_as_jira]).to be_skipped
      expect(report.group(:authorization)[:credentials_accepted].code).to eq(:credentials_rejected)
    end
  end

  context "when Jira answers the server info anonymously, like Jira 8, and rejects the credentials" do
    before { stub_request(:get, "#{url}/rest/api/2/mypermissions").to_return(status: 401) }

    it "reports the rejected credentials in the authorization group" do
      expect(report.group(:server)).to be_success
      expect(report.group(:authorization)[:credentials_accepted].code).to eq(:credentials_rejected)
    end
  end
end
