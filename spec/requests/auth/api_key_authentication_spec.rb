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

RSpec.describe "Authentication with an API key",
               with_config: { apiv3_enable_basic_auth: true },
               with_settings: { login_required: true } do
  let(:user) { create(:user) }
  let(:token) { create(:api_token, user:) }
  let(:api_key) { token.plain_value }

  shared_examples "an API key authentication path" do
    it "authenticates with a valid API key" do
      send_request

      expect(last_response).to have_http_status(:ok)
    end

    it "rejects an expired API key" do
      token.update_column(:expires_on, 1.day.ago)

      send_request

      expect(last_response).to have_http_status(:unauthorized)
    end

    context "with an unknown API key" do
      let(:api_key) { "#{Token::API.prefix}-#{SecureRandom.hex(32)}" }

      it "rejects it" do
        send_request

        expect(last_response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "APIv3" do
    context "with the API key as Bearer token" do
      subject(:send_request) do
        header "Authorization", "Bearer #{api_key}"
        get "/api/v3/users/me"
      end

      it_behaves_like "an API key authentication path"
    end

    context "with the API key via Basic auth" do
      subject(:send_request) do
        header "Authorization", ActionController::HttpAuthentication::Basic.encode_credentials("apikey", api_key)
        get "/api/v3/users/me"
      end

      it_behaves_like "an API key authentication path"
    end
  end

  describe "MCP", with_ee: %i[mcp_server] do
    let(:mcp_request_body) { { jsonrpc: "2.0", id: "api-key-auth", method: "tools/list", params: {} }.to_json }

    before do
      create(:mcp_configuration, identifier: "mcp_server")
    end

    context "with the API key as Bearer token" do
      subject(:send_request) do
        header "Authorization", "Bearer #{api_key}"
        header "Content-Type", "application/json"
        post "/mcp", mcp_request_body
      end

      it_behaves_like "an API key authentication path"
    end

    context "with the API key via Basic auth" do
      subject(:send_request) do
        header "Authorization", ActionController::HttpAuthentication::Basic.encode_credentials("apikey", api_key)
        header "Content-Type", "application/json"
        post "/mcp", mcp_request_body
      end

      it_behaves_like "an API key authentication path"
    end
  end

  describe "Rails controllers accepting key auth", with_settings: { login_required: false } do
    let(:hook_name) { "api_key_authentication_spec" }

    before do
      token_owner = user
      OpenProject::Webhooks.register_hook(hook_name) do |_hook, _request, _params, current_user|
        current_user == token_owner ? 200 : 401
      end
    end

    after do
      OpenProject::Webhooks.unregister_hook(hook_name)
    end

    context "with the API key as key param" do
      subject(:send_request) do
        header "Content-Type", "application/json"
        post "/webhooks/#{hook_name}?key=#{api_key}", "{}"
      end

      it_behaves_like "an API key authentication path"
    end

    context "with the API key in the X-OpenProject-API-Key header" do
      subject(:send_request) do
        header "Content-Type", "application/json"
        header "X-OpenProject-API-Key", api_key
        post "/webhooks/#{hook_name}", "{}"
      end

      it_behaves_like "an API key authentication path"
    end
  end
end
