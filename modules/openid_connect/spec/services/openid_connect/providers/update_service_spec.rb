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
require "services/base_services/behaves_like_update_service"

RSpec.describe OpenIDConnect::Providers::UpdateService, type: :model do
  it_behaves_like "BaseServices update service" do
    let(:factory) { :oidc_provider }
  end

  describe "metadata fetching" do
    subject(:service_call) do
      described_class
        .new(model: provider, user: admin, fetch_metadata: true)
        .call(metadata_url:)
    end

    let(:admin) { build_stubbed(:admin) }
    let(:provider) { create(:oidc_provider, oidc_provider: "custom") }
    let(:metadata_url) { "https://example.com/.well-known/openid-configuration" }

    context "when metadata endpoint returns valid JSON" do
      let(:http_response) do
        instance_double(HTTPX::Response,
                        status: 200,
                        json: {
                          authorization_endpoint: "https://example.com/authorize",
                          userinfo_endpoint: "https://example.com/userinfo",
                          token_endpoint: "https://example.com/token",
                          issuer: "https://example.com",
                          jwks_uri: "https://example.com/jwks"
                        })
      end

      before do
        httpx_session = instance_double(HTTPX::Session)
        allow(OpenProject::SsrfProtection).to receive(:safe_ip?).with("example.com").and_return(IPAddr.new("93.184.216.34"))
        allow(httpx_session).to receive(:get).with(metadata_url).and_return(http_response)
        allow(OpenProject).to receive(:httpx).and_return(httpx_session)
      end

      it "updates provider metadata from the response body" do
        result = service_call

        expect(result).to be_success
        expect(result.result.authorization_endpoint).to eq("https://example.com/authorize")
        expect(result.result.userinfo_endpoint).to eq("https://example.com/userinfo")
        expect(result.result.token_endpoint).to eq("https://example.com/token")
        expect(result.result.issuer).to eq("https://example.com")
        expect(result.result.jwks_uri).to eq("https://example.com/jwks")
      end
    end

    context "when SSRF protection blocks the target address" do
      let(:httpx_session) { instance_double(HTTPX::Session) }

      before do
        allow(OpenProject::SsrfProtection).to receive(:safe_ip?).with("example.com").and_return(nil)
        allow(httpx_session).to receive(:get)
        allow(OpenProject).to receive(:httpx).and_return(httpx_session)
      end

      it "fails without issuing the request" do
        result = service_call

        expect(result).not_to be_success
        expect(result.errors[:metadata_url]).to include("violates the SSRF policy of this OpenProject instance.")
        expect(httpx_session).not_to have_received(:get)
      end
    end
  end
end
