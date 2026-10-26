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

  describe "work package Markdown export",
           with_settings: { login_required: true, session_ttl_enabled?: true, session_ttl: "120" } do
    let(:work_package) { create(:work_package) }
    let(:user) do
      create(:user, member_with_permissions: { work_package.project => %i[view_work_packages] })
    end

    context "with the key in the X-OpenProject-API-Key header and the .md suffix" do
      subject(:send_request) do
        header "X-OpenProject-API-Key", api_key
        get "/work_packages/#{work_package.id}.md"
      end

      it_behaves_like "an API key authentication path"
    end

    context "with the key and Accept: text/markdown" do
      subject(:send_request) do
        header "X-OpenProject-API-Key", api_key
        header "Accept", "text/markdown"
        get "/work_packages/#{work_package.id}"
      end

      it_behaves_like "an API key authentication path"
    end

    it "answers 401 with WWW-Authenticate without credentials" do
      get "/work_packages/#{work_package.id}.md"

      expect(last_response).to have_http_status(:unauthorized)
      expect(last_response.headers["WWW-Authenticate"]).to be_present
      expect(last_response.media_type).to eq("text/markdown")
      expect(last_response.body).to eq(I18n.t(:text_markdown_login_required))
    end

    it "answers 401 with WWW-Authenticate for Accept: text/markdown without credentials" do
      header "Accept", "text/markdown"
      get "/work_packages/#{work_package.id}"

      expect(last_response).to have_http_status(:unauthorized)
      expect(last_response.headers["WWW-Authenticate"]).to be_present
      expect(last_response.media_type).to eq("text/markdown")
      expect(last_response.body).to eq(I18n.t(:text_markdown_login_required))
    end

    it "ignores the key on the html format" do
      header "X-OpenProject-API-Key", api_key
      get "/work_packages/#{work_package.id}"

      expect(last_response).to be_redirect
      expect(last_response.location).to include("/login")
    end

    ["application/json, text/html", "application/xml, text/html"].each do |accept|
      it "ignores the key when Accept: #{accept} falls back to html" do
        header "X-OpenProject-API-Key", api_key
        header "Accept", accept
        get "/projects/#{work_package.project.identifier}/work_packages/#{work_package.id}/activity"

        expect(last_response).not_to have_http_status(:ok)
        expect(last_response.media_type).not_to eq("text/html")
      end
    end

    it "authenticates the key when Accept prefers text/markdown over text/html" do
      header "X-OpenProject-API-Key", api_key
      header "Accept", "text/markdown, text/html"
      get "/work_packages/#{work_package.id}"

      expect(last_response).to have_http_status(:ok)
      expect(last_response.media_type).to eq("text/markdown")
    end

    context "with header-based SSO enabled" do
      before do
        allow(OpenProject::Configuration)
          .to receive(:auth_source_sso)
          .and_return({ header: "X-Remote-User", optional: true })
      end

      it "ignores the SSO header on a key-authenticated request" do
        header "X-OpenProject-API-Key", api_key
        header "X-Remote-User", user.login
        get "/work_packages/#{work_package.id}.md"

        expect(last_response).to have_http_status(:ok)
        expect(last_response.media_type).to eq("text/markdown")
        expect(last_response.headers["Set-Cookie"]).to be_blank
      end

      it "ignores an SSO header naming a different user in favor of the key" do
        header "X-OpenProject-API-Key", api_key
        header "X-Remote-User", create(:user).login
        get "/work_packages/#{work_package.id}.md"

        expect(last_response).to have_http_status(:ok)
        expect(last_response.body).to start_with("# #{work_package.type.name} #{work_package.formatted_id} - ")
        expect(last_response.headers["Set-Cookie"]).to be_blank
      end
    end

    context "with mandatory header-based SSO" do
      before do
        allow(OpenProject::Configuration)
          .to receive(:auth_source_sso)
          .and_return({ header: "X-Remote-User", optional: false })
      end

      it "rejects a key-authenticated request without the SSO header like a keyless one" do
        header "X-OpenProject-API-Key", api_key
        get "/work_packages/#{work_package.id}.md"

        expect(last_response).to be_redirect
        expect(last_response.location).to end_with("/sso")
        expect(last_response.body).not_to include(work_package.subject)
      end

      it "rejects a keyless request without the SSO header" do
        get "/work_packages/#{work_package.id}.md"

        expect(last_response).to be_redirect
        expect(last_response.location).to end_with("/sso")
      end

      it "rejects a retried key-authenticated request without the SSO header" do
        2.times do
          header "X-OpenProject-API-Key", api_key
          get "/work_packages/#{work_package.id}.md"

          expect(last_response).to be_redirect
          expect(last_response.location).to end_with("/sso")
          expect(last_response.body).not_to include(work_package.subject)
        end
      end

      context "with an SSO secret configured" do
        before do
          allow(OpenProject::Configuration)
            .to receive(:auth_source_sso)
            .and_return({ header: "X-Remote-User", secret: "s3cret", optional: false })
        end

        it "rejects a retried key-authenticated request with an invalid SSO secret" do
          2.times do
            header "X-OpenProject-API-Key", api_key
            header "X-Remote-User", "#{user.login}:wrong"
            get "/work_packages/#{work_package.id}.md"

            expect(last_response).to be_redirect
            expect(last_response.location).to end_with("/sso")
            expect(last_response.body).not_to include(work_package.subject)
          end
        end
      end
    end

    it "does not start a session" do
      header "X-OpenProject-API-Key", api_key
      get "/work_packages/#{work_package.id}.md"

      expect(last_response).to have_http_status(:ok)
      expect(last_response.headers["Set-Cookie"]).to be_blank
    end

    it "serves a key-authenticated request despite an expired session cookie", :skip_csrf do
      post "/login", username: user.login, password: "adminADMIN!"
      follow_redirect! while last_response.redirect?
      expect(last_request.env["rack.session"]["user_id"]).to eq(user.id)

      travel 3.hours
      header "X-OpenProject-API-Key", api_key
      get "/work_packages/#{work_package.id}.md"

      expect(last_response).to have_http_status(:ok)
      expect(last_response.headers["Set-Cookie"]).to be_blank
    end

    it "expires the session when the key resolves to a user that is not accepted", :skip_csrf do
      post "/login", username: user.login, password: "adminADMIN!"
      follow_redirect! while last_response.redirect?
      allow(User).to receive(:find_by_api_key).and_return(create(:locked_user))

      travel 3.hours
      header "X-OpenProject-API-Key", api_key
      get "/work_packages/#{work_package.id}.md"

      expect(last_response).to be_redirect
      expect(last_response.location).to include("/login")
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
