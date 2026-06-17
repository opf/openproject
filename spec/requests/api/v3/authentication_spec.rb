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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "API V3 Authentication" do
  let(:resource) { "/api/v3/projects" }
  let(:user) { create(:user) }
  let(:error_response_body) do
    {
      "_type" => "Error",
      "errorIdentifier" => "urn:openproject-org:api:v3:errors:Unauthenticated",
      "message" => expected_message
    }
  end
  let(:resource_metadata) { 'resource_metadata="http://test.host/.well-known/oauth-protected-resource"' }

  describe "session auth" do
    let(:user) { create(:admin) }
    let(:session_data) { ActiveSupport::HashWithIndifferentAccess.new(user_id: user.id, updated_at: Time.current) }

    before do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(OpenProject::Authentication::Strategies::Warden::Session)
        .to receive(:session)
        .and_return(session_data)
      # rubocop:enable RSpec/AnyInstance
    end

    context "when making a GET request" do
      before do
        get resource
      end

      it "authenticates successfully" do
        expect(last_response).to have_http_status :ok
      end
    end

    context "when making a POST request" do
      let(:add_additional_headers) { nil }

      before do
        header "Content-Type", "application/json"
        add_additional_headers
        post resource, { name: "Test" }.to_json
      end

      it "is not authenticated" do
        expect(last_response).to have_http_status :unauthorized
      end

      context "and when the Sec-Fetch-Site header indicates a same-origin request" do
        let(:add_additional_headers) { header "Sec-Fetch-Site", "same-origin" }

        it "authenticates successfully" do
          expect(last_response).to have_http_status :created
        end
      end

      context "and when the Sec-Fetch-Site header indicates a cross-site request" do
        let(:add_additional_headers) { header "Sec-Fetch-Site", "cross-site" }

        it "is not authenticated" do
          expect(last_response).to have_http_status :unauthorized
        end
      end

      context "and when the Sec-Fetch-Site header indicates a same-site request" do
        let(:add_additional_headers) { header "Sec-Fetch-Site", "same-site" }

        it "is not authenticated" do
          expect(last_response).to have_http_status :unauthorized
        end
      end

      context "and when there is an X-Requested-With: XMLHttpRequest header when HTTPS is enabled",
              with_settings: { https: true } do
        let(:add_additional_headers) { header "X-Requested-With", "XMLHttpRequest" }

        # in HTTPS setups we ignore this header, because the safer alternative is available
        it "is not authenticated" do
          expect(last_response).to have_http_status :unauthorized
        end
      end

      context "and when there is an X-Requested-With: XMLHttpRequest header when HTTPS is disabled",
              with_settings: { https: false } do
        let(:add_additional_headers) { header "X-Requested-With", "XMLHttpRequest" }

        # in HTTP setups we still accept the header for backwards-compatibility
        it "authenticates successfully" do
          expect(last_response).to have_http_status :created
        end
      end
    end
  end

  describe "oauth" do
    let(:oauth_access_token) { "" }
    let(:expected_message) { "You did not provide the correct credentials." }

    before do
      user

      header "Authorization", "Bearer #{oauth_access_token}"

      get resource
    end

    context "with a valid access token" do
      let(:token) { create(:oauth_access_token, resource_owner: user) }
      let(:oauth_access_token) { token.plaintext_token }

      it "authenticates successfully" do
        expect(last_response).to have_http_status :ok
      end
    end

    context "with an invalid access token" do
      let(:oauth_access_token) { "1337" }
      let(:expected_www_auth_header) do
        %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3", error="invalid_token"}
      end

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "with a revoked access token" do
      let(:token) { create(:oauth_access_token, resource_owner: user, revoked_at: DateTime.now) }
      let(:oauth_access_token) { token.plaintext_token }
      let(:expected_www_auth_header) do
        %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3", error="invalid_token"}
      end

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when the token's application is disabled" do
      let(:token) { create(:oauth_access_token, resource_owner: user, application: create(:oauth_application, enabled: false)) }
      let(:oauth_access_token) { token.plaintext_token }
      let(:expected_www_auth_header) do
        %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3", error="invalid_token"}
      end

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "with an expired access token" do
      let(:token) { create(:oauth_access_token, resource_owner: user) }
      let(:oauth_access_token) { token.plaintext_token }
      let(:expected_www_auth_header) do
        %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3", error="invalid_token"}
      end

      around do |ex|
        Timecop.freeze(Time.current + (token.expires_in + 5).seconds) do
          ex.run
        end
      end

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "with wrong scope" do
      let(:token) { create(:oauth_access_token, resource_owner: user, scopes: "unknown_scope") }
      let(:oauth_access_token) { token.plaintext_token }
      let(:expected_www_auth_header) do
        %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3", error="insufficient_scope"}
      end

      it "returns forbidden" do
        expect(last_response).to have_http_status :forbidden
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when the token's resource owner can't be found" do
      let(:token) { create(:oauth_access_token, resource_owner: user, application:) }
      let(:application) { create(:oauth_application) }
      let(:oauth_access_token) { token.plaintext_token }
      let(:expected_www_auth_header) do
        %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3", error="invalid_token"}
      end

      around do |ex|
        user.destroy
        ex.run
      end

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end

      context "when the application has a client credentials user configured" do
        let(:application) { create(:oauth_application, client_credentials_user_id: create(:user).id) }

        it "returns unauthorized" do
          expect(last_response).to have_http_status :unauthorized
          expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
          expect(JSON.parse(last_response.body)).to eq(error_response_body)
        end
      end
    end

    context "when the token's resource owner is locked" do
      let(:token) { create(:oauth_access_token, resource_owner: user) }
      let(:oauth_access_token) { token.plaintext_token }
      let(:user) { create(:user, :locked) }
      let(:expected_www_auth_header) do
        %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3", error="invalid_token"}
      end

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when there is no resource owner on the token" do
      let(:token) { create(:oauth_access_token, resource_owner: nil, application:) }
      let(:application) { create(:oauth_application) }
      let(:oauth_access_token) { token.plaintext_token }
      let(:expected_www_auth_header) do
        %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3"}
      end

      # Note: This is just caused by DoorkeeperOauth rejecting to handle this case and auth falling through to basic auth
      # more specific examples can be found at spec/requests/oauth/client_credentials_flow_spec.rb
      let(:expected_message) { "You need to be authenticated to access this resource." }

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end

      context "when the application has a client credentials user configured" do
        let(:application) { create(:oauth_application, client_credentials_user_id: user.id) }

        it "authenticates successfully" do
          expect(last_response).to have_http_status :ok
        end

        context "and the client credentials user is locked" do
          let(:user) { create(:user, :locked) }
          let(:expected_message) { "You did not provide the correct credentials." }
          let(:expected_www_auth_header) do
            %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3", error="invalid_token"}
          end

          it "returns unauthorized" do
            expect(last_response).to have_http_status :unauthorized
            expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
            expect(JSON.parse(last_response.body)).to eq(error_response_body)
          end
        end
      end
    end
  end

  describe "API Key as Bearer token" do
    let(:token) { create(:api_token, user:) }
    let(:bearer_token) { token.plain_value }
    let(:expected_message) { "You did not provide the correct credentials." }

    before do
      user

      header "Authorization", "Bearer #{bearer_token}"

      get resource
    end

    context "with a valid access token" do
      it "authenticates successfully" do
        expect(last_response).to have_http_status :ok
      end
    end

    context "with an invalid access token" do
      let(:bearer_token) { "opapi-1337" }
      let(:expected_www_auth_header) do
        %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3", error="invalid_token"}
      end

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when the token's user can't be found" do
      let(:expected_www_auth_header) do
        %{Bearer realm="OpenProject API", #{resource_metadata}, scope="api_v3", error="invalid_token"}
      end

      around do |ex|
        # create the token before deleting the user; right now it especially works, because a foreign key constraint prevents
        # tokens without users
        token
        user.destroy!
        ex.run
      end

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when the token's user is locked" do
      let(:user) { create(:user, :locked) }
      let(:expected_www_auth_header) do
        "Bearer realm=\"OpenProject API\", #{resource_metadata}, scope=\"api_v3\", error=\"invalid_token\", " \
          "error_description=\"#{expected_error_description}\""
      end
      let(:expected_error_description) { "The user account is locked" }

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end
  end

  describe "basic auth" do
    let(:expected_message) { "You need to be authenticated to access this resource." }

    strategies = OpenProject::Authentication::Strategies::Warden

    def set_basic_auth_header(user, password)
      credentials = ActionController::HttpAuthentication::Basic.encode_credentials user, password
      header "Authorization", credentials
    end

    shared_examples "it is basic auth protected" do
      context "when not allowed", with_config: { apiv3_enable_basic_auth: false } do
        context "with valid credentials" do
          before do
            set_basic_auth_header(username, password)
            get resource
          end

          it "returns 401 unauthorized" do
            expect(last_response).to have_http_status :unauthorized
          end
        end
      end

      context "when allowed", with_config: { apiv3_enable_basic_auth: true } do
        context "without credentials" do
          before do
            get resource
          end

          it "returns 401 unauthorized" do
            expect(last_response).to have_http_status :unauthorized
          end

          it "returns the correct JSON response" do
            expect(JSON.parse(last_response.body)).to eq error_response_body
          end

          it "returns the WWW-Authenticate header" do
            expect(last_response.header["WWW-Authenticate"]).to include 'Bearer realm="OpenProject API"'
          end
        end

        context "with invalid credentials" do
          let(:expected_message) { "You did not provide the correct credentials." }

          before do
            set_basic_auth_header(username, password.reverse)
            get resource
          end

          it "returns 401 unauthorized" do
            expect(last_response).to have_http_status :unauthorized
          end

          it "returns the correct JSON response" do
            expect(JSON.parse(last_response.body)).to eq error_response_body
          end

          it "returns the correct content type header" do
            expect(last_response.headers["Content-Type"]).to eq "application/hal+json; charset=utf-8"
          end

          it "returns the WWW-Authenticate header" do
            expect(last_response.header["WWW-Authenticate"])
              .to include 'Basic realm="OpenProject API"'
          end
        end

        context "with no credentials" do
          let(:expected_message) { "You need to be authenticated to access this resource." }

          before do
            post "/api/v3/time_entries/form"
          end

          it "returns 401 unauthorized" do
            expect(last_response).to have_http_status :unauthorized
          end

          it "returns the correct JSON response" do
            expect(JSON.parse(last_response.body)).to eq error_response_body
          end

          it "returns the correct content type header" do
            expect(last_response.headers["Content-Type"]).to eq "application/hal+json; charset=utf-8"
          end

          it "returns the WWW-Authenticate header" do
            expect(last_response.header["WWW-Authenticate"])
              .to include 'Bearer realm="OpenProject API"'
          end
        end

        context "with valid credentials" do
          before do
            set_basic_auth_header(username, password)
            get resource
          end

          it "returns 200 OK" do
            expect(last_response).to have_http_status :ok
          end
        end
      end
    end

    context "with login required" do
      before do
        allow(Setting).to receive_messages(login_required: true, login_required?: true)
      end

      context "with global basic auth configured" do
        let(:username) { "root" }
        let(:password) { "toor" }

        before do
          strategies::GlobalBasicAuth.configure! user: "root", password: "toor"
        end

        it_behaves_like "it is basic auth protected"

        describe "user basic auth" do
          let(:api_key) { create(:api_token) }

          let(:username) { "apikey" }
          let(:password) { api_key.plain_value }

          # check that user basic auth is tried when global basic auth fails
          it_behaves_like "it is basic auth protected"
        end
      end

      describe "user basic auth" do
        let(:api_key) { create(:api_token) }

        let(:username) { "apikey" }
        let(:password) { api_key.plain_value }

        # check that user basic auth works on its own too
        it_behaves_like "it is basic auth protected"
      end
    end

    context "when enabled", with_config: { apiv3_enable_basic_auth: true } do
      context "without login required" do
        before do
          allow(Setting).to receive_messages(login_required: false, login_required?: false)
        end

        context "with global and user basic auth enabled" do
          let(:username) { "hancholo" }
          let(:password) { "olooleol" }

          let(:api_user) { create(:user, login: "user_account") }
          let(:api_key) { create(:api_token, user: api_user) }

          before do
            config = { user: "global_account", password: "global_password" }
            strategies::GlobalBasicAuth.configure! config
          end

          context "without credentials" do
            before do
              get resource
            end

            it "returns 200 OK" do
              expect(last_response).to have_http_status :ok
            end

            it '"login"s the anonymous user' do
              expect(User.current).to be_anonymous
            end
          end

          context "with invalid credentials" do
            before do
              set_basic_auth_header(username, password)
              get resource
            end

            it "returns 401 unauthorized" do
              expect(last_response).to have_http_status :unauthorized
            end
          end

          context "with valid global credentials" do
            before do
              set_basic_auth_header("global_account", "global_password")
              get resource
            end

            it "returns 200 OK" do
              expect(last_response).to have_http_status :ok
            end
          end

          context "with valid user credentials" do
            before do
              set_basic_auth_header("apikey", api_key.plain_value)
              get resource
            end

            it "returns 200 OK" do
              expect(last_response).to have_http_status :ok
            end
          end
        end
      end
    end
  end

  describe("OIDC", :webmock) do
    let(:jwk) { JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), kid: "my-kid", use: "sig", alg: "RS256") }
    let(:payload) do
      {
        "exp" => token_exp.to_i,
        "iat" => 1721283370,
        "jti" => "c526b435-991f-474a-ad1b-c371456d1fd0",
        "iss" => token_issuer,
        "aud" => token_aud,
        "sub" => token_sub,
        "typ" => "Bearer",
        "azp" => "https://openproject.local",
        "session_state" => "eb235240-0b47-48fa-8b3e-f3b310d352e3",
        "acr" => "1",
        "allowed-origins" => ["https://openproject.local"],
        "realm_access" => { "roles" => ["create-realm", "default-roles-master", "offline_access", "admin", "uma_authorization"] },
        "resource_access" =>
        { "master-realm" =>
          { "roles" =>
            ["view-realm",
             "view-identity-providers",
             "manage-identity-providers",
             "impersonation",
             "create-client",
             "manage-users",
             "query-realms",
             "view-authorization",
             "query-clients",
             "query-users",
             "manage-events",
             "manage-realm",
             "view-events",
             "view-users",
             "view-clients",
             "manage-authorization",
             "manage-clients",
             "query-groups"] },
          "account" => { "roles" => ["manage-account", "manage-account-links", "view-profile"] } },
        "scope" => token_scope,
        "sid" => "eb235240-0b47-48fa-8b3e-f3b310d352e3",
        "email_verified" => false,
        "preferred_username" => "admin"
      }
    end
    let(:token) { JWT.encode(payload, jwk.signing_key, jwk[:alg], { kid: jwk[:kid] }) }
    let(:token_exp) { 5.minutes.from_now }
    let(:token_sub) { "b70e2fbf-ea68-420c-a7a5-0a287cb689c6" }
    let(:token_aud) { ["https://openproject.local", "master-realm", "account"] }
    let(:token_issuer) { "https://keycloak.local/realms/master" }
    let(:token_scope) { "email profile api_v3" }
    let(:expected_message) { "You did not provide the correct credentials." }
    let(:expected_www_auth_header) do
      "Bearer realm=\"OpenProject API\", #{resource_metadata}, scope=\"api_v3\", error=\"#{expected_error}\", " \
        "error_description=\"#{expected_error_description}\""
    end
    let(:expected_error) { "invalid_token" }
    let(:keys_request_stub) do
      stub_request(:get, "https://keycloak.local/realms/master/protocol/openid-connect/certs")
        .to_return(status: 200, body: JWT::JWK::Set.new(jwk_response).export.to_json, headers: {})
    end
    let(:jwk_response) { jwk }
    let(:user) { create(:user, authentication_provider: create(:oidc_provider), external_id: token_sub) }

    before do
      user.save!
      keys_request_stub

      header "Authorization", "Bearer #{token}"
    end

    it "succeeds" do
      get resource

      expect(last_response).to have_http_status :ok
      expect(last_response.header["WWW-Authenticate"]).to be_blank
    end

    context "when token is issued by provider not configured in OP" do
      let(:token_issuer) { "https://eve.example.com" }
      let(:expected_error_description) { "The access token issuer is unknown" }

      it "fails with HTTP 401 Unauthorized" do
        get resource
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when token signature algorithm is not supported" do
      let(:token) { JWT.encode(payload, "secret", "HS256", { kid: "97AmyvoS8BFFRfm585GPgA16G1H2V22EdxxuAYUuoKk" }) }
      let(:expected_error_description) { "Token signature algorithm HS256 is not supported" }

      it "fails with HTTP 401 Unauthorized" do
        get resource
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when aud does not contain client_id" do
      let(:token_aud) { ["Lisa", "Bart"] }
      let(:expected_error_description) { 'Invalid audience. Expected https://openproject.local, received [\"Lisa\", \"Bart\"]' }

      it "fails with HTTP 401 Unauthorized" do
        get resource

        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when the scope does not permit access to APIv3" do
      let(:token_scope) { "profile email" }
      let(:expected_error) { "insufficient_scope" }
      let(:expected_error_description) { "Requires scope api_v3 to access this resource." }

      it "fails with HTTP 403 Forbidden" do
        get resource

        expect(last_response).to have_http_status :forbidden
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when access token has expired already" do
      let(:token_exp) { 5.minutes.ago }
      let(:expected_error_description) { "Signature has expired" }

      it "fails with HTTP 401 Unauthorized" do
        get resource

        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end

      it "caches keys request to keycloak" do
        get resource
        expect(last_response).to have_http_status :unauthorized

        get resource
        expect(last_response).to have_http_status :unauthorized

        expect(keys_request_stub).to have_been_made.once
      end
    end

    context "when kid is absent in keycloak keys response" do
      let(:jwk_response) { JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), kid: "your-kid", use: "sig", alg: "RS256") }
      let(:expected_error_description) { "The signature key ID is unknown" }

      it "fails with HTTP 401 Unauthorized" do
        get resource
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when user identified by token is not known" do
      let(:user) { create(:user, authentication_provider: create(:oidc_provider)) }
      let(:expected_error_description) { "The user identified by the token is not known" }

      it "fails with HTTP 401 Unauthorized" do
        get resource
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when user identified by token is locked" do
      let(:user) { create(:user, :locked, authentication_provider: create(:oidc_provider), external_id: token_sub) }
      let(:expected_error_description) { "The user account is locked" }

      it "fails with HTTP 401 Unauthorized" do
        get resource
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq(expected_www_auth_header)
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end
  end
end
