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

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq('Bearer realm="OpenProject API" error="invalid_token"')
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "with a revoked access token" do
      let(:token) { create(:oauth_access_token, resource_owner: user, revoked_at: DateTime.now) }
      let(:oauth_access_token) { token.plaintext_token }

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq('Bearer realm="OpenProject API" error="invalid_token"')
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "with an expired access token" do
      let(:token) { create(:oauth_access_token, resource_owner: user) }
      let(:oauth_access_token) { token.plaintext_token }

      around do |ex|
        Timecop.freeze(Time.current + (token.expires_in + 5).seconds) do
          ex.run
        end
      end

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq('Bearer realm="OpenProject API" error="invalid_token"')
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "with wrong scope" do
      let(:token) { create(:oauth_access_token, resource_owner: user, scopes: "unknown_scope") }
      let(:oauth_access_token) { token.plaintext_token }

      it "returns forbidden" do
        expect(last_response).to have_http_status :forbidden
        expect(last_response.header["WWW-Authenticate"]).to eq('Bearer realm="OpenProject API" error="insufficient_scope"')
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "with not found user" do
      let(:token) { create(:oauth_access_token, resource_owner: user) }
      let(:oauth_access_token) { token.plaintext_token }

      around do |ex|
        user.destroy
        ex.run
      end

      it "returns unauthorized" do
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq('Bearer realm="OpenProject API" error="invalid_token"')
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
            expect(last_response.header["WWW-Authenticate"]).to include 'Basic realm="OpenProject API"'
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
              .to include 'Basic realm="OpenProject API"'
          end
        end

        context 'with invalid credentials an X-Authentication-Scheme "Session"' do
          let(:expected_message) { "You did not provide the correct credentials." }

          before do
            set_basic_auth_header(username, password.reverse)
            header "X-Authentication-Scheme", "Session"
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
              .to include 'Session realm="OpenProject API"'
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

  describe(
    "OIDC",
    :webmock,
    with_settings: {
      plugin_openproject_openid_connect: {
        "providers" => {
          "keycloak" => {
            "display_name" => "Keycloak",
            "identifier" => "https://openproject.internal",
            "secret" => "9AWjVC3A4U1HLrZuSP4xiwHfw6zmgECn",
            "host" => "keycloak.internal",
            "issuer" => "https://keycloak.internal/realms/master",
            "authorization_endpoint" => "/realms/master/protocol/openid-connect/auth",
            "token_endpoint" => "/realms/master/protocol/openid-connect/token",
            "userinfo_endpoint" => "/realms/master/protocol/openid-connect/userinfo",
            "end_session_endpoint" => "https://keycloak.internal/realms/master/protocol/openid-connect/logout",
            "jwks_uri" => "https://keycloak.internal/realms/master/protocol/openid-connect/certs"
          }
        }
      }
    }
  ) do
    let(:expected_message) { "You did not provide the correct credentials." }
    let(:token) do
      JWT.encode(token_payload, rsa_private, "RS256", kid: jwk[:kid])
    end
    let(:token_payload) do
      { "exp" => 1721283430,
        "iat" => 1721283370,
        "jti" => "c526b435-991f-474a-ad1b-c371456d1fd0",
        "iss" => token_iss,
        "aud" => token_aud,
        "sub" => "b70e2fbf-ea68-420c-a7a5-0a287cb689c6",
        "typ" => "Bearer",
        "azp" => "https://openproject.internal",
        "session_state" => "eb235240-0b47-48fa-8b3e-f3b310d352e3",
        "acr" => "1",
        "allowed-origins" => ["https://openproject.internal"],
        "realm_access" => { "roles" => ["create-realm", "default-roles-master", "offline_access", "admin",
                                        "uma_authorization"] },
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
        "scope" => "email profile",
        "sid" => "eb235240-0b47-48fa-8b3e-f3b310d352e3",
        "email_verified" => false,
        "preferred_username" => "admin" }
    end
    let(:token_aud) { ["master-realm", "account"] }
    let(:token_exp) { Time.zone.at(JWT.decode(token, nil, false)[0]["exp"]) }
    let(:token_sub) { JWT.decode(token, nil, false)[0]["sub"] }
    let(:token_iss) { "https://keycloak.internal/realms/master" }
    let(:keys_request_stub) do
      stub_request(:get, "https://keycloak.internal/realms/master/protocol/openid-connect/certs")
        .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "User-Agent" => "JSON::JWK::Set::Fetcher 2.7.2"
          }
        ).to_return(status: 200, body: keys_hash.to_json, headers: {})
    end
    let(:keys_hash) do
      { "keys" =>
        [{ "kid" => "CANAG6lJUPKqKDoWxxXL5wAHf2U18BAzm_LJm7RPTGk",
           "kty" => "RSA",
           "alg" => "RSA-OAEP",
           "use" => "enc",
           "n" =>
           "nqJexS6n-SxKSDUxXp_dsNwDW6cZ4Rtgqq9ut_lp1CNSph5wTnLG3aQQsTEvx5o3-SZ-pHjJ0gtEpg7clAz-w-YQyZoAXkFtQqmZJxsmdS4K0yILxO3WUNdJQlutjmq-Ri50Senn5IV7yEYWLo8St1qzUqWZhp0HKudyty24triC9UJTK03W3_Tr5c1X8vKL8duAjvLB7p_sYUOrnLq5pD5lqwxVSAiN8qS5zVNZMrhGV5aN1vN_vue_tw8c2SVOCLLTrUh3441rYaeo-UwQZF7ZTm30xflqAIfe8qMoB20wtWYAXR0D5iqkkdEH4XanCYVm5vdUFIPPvXZhRDWoNQ",
           "e" => "AQAB",
           "x5c" =>
           ["MIICmzCCAYMCBgGQupeGPzANBgkqhkiG9w0BAQsFADARMQ8wDQYDVQQDDAZtYXN0ZXIwHhcNMjQwNzE2MDgwODMwWhcNMzQwNzE2MDgxMDEwWjARMQ8wDQYDVQQDDAZtYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCeol7FLqf5LEpINTFen92w3ANbpxnhG2Cqr263+WnUI1KmHnBOcsbdpBCxMS/Hmjf5Jn6keMnSC0SmDtyUDP7D5hDJmgBeQW1CqZknGyZ1LgrTIgvE7dZQ10lCW62Oar5GLnRJ6efkhXvIRhYujxK3WrNSpZmGnQcq53K3Lbi2uIL1QlMrTdbf9OvlzVfy8ovx24CO8sHun+xhQ6ucurmkPmWrDFVICI3ypLnNU1kyuEZXlo3W83++57+3DxzZJU4IstOtSHfjjWthp6j5TBBkXtlObfTF+WoAh97yoygHbTC1ZgBdHQPmKqSR0QfhdqcJhWbm91QUg8+9dmFENag1AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAB/AGvP0gviPoJszj/oQgBsMpPGRHLpnTmrXnTaa7Xk2sgExAb4zUAwxGjtR347t697cpiKQYBkR2ndswnt93Sx/Ot+yn5BdYcNvZuEh5jb5bkH2V4h6/LrYljTymby+XPBEf+XLhBOjoI3SKtNJk4pEqVNwLuKKbObqJcE3G3VBVSdzRUcIrjZr7yAQeLnhczS3hJ0Ct6Y7S5Q6DK+/PU1+AvlW+7GfzpRMqVfLcqhNpRwdCVGlJYKaUJfIe1vav10D94xA0U1sKex3iA1S+1HlS2BCWx/0rXwgcquMpUZlOAKiT0K6SIFxBFFnM9eQbF97Dz7Bzw+jyqStGUcH9YA="],
           "x5t" => "TuBfrOL00KXDrOWTv3jw7Uxx3hA",
           "x5t#S256" => "7su5lOXF5qcMuvp44ynsoyk3B0l9Sr_bOVlg768shpY" },
         jwk] }
    end
    let(:jwk) { JWT::JWK.create_from(rsa_public).export }
    let(:rsa_private) { OpenSSL::PKey::RSA.generate(2048) }
    let(:rsa_public) { rsa_private.public_key }

    before do
      create(:user, identity_url: "keycloak:#{token_sub}")
      keys_request_stub

      header "Authorization", "Bearer #{token}"
    end

    context "when token is issued by provider not configured in OP" do
      let(:token_iss) { "https://unk.asd" }

      it do
        get resource
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq("Bearer realm=\"OpenProject API\" error=\"invalid_token\" error_description=\"The access token issuer is unknown\"")
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when token is issued by provider configured in OP" do
      context "when token signature algorithm is not supported" do
        let(:token) { JWT.encode(token_payload, "hmac_secret", "HS256") }

        it do
          get resource
          expect(last_response).to have_http_status :unauthorized
          expect(last_response.header["WWW-Authenticate"]).to eq("Bearer realm=\"OpenProject API\" error=\"invalid_token\" error_description=\"Token signature algorithm is not supported\"")
          expect(JSON.parse(last_response.body)).to eq(error_response_body)
        end
      end

      context "when access token has not expired yet" do
        context "when aud does not contain client_id" do
          it do
            Timecop.freeze(token_exp - 20.seconds) do
              get resource
            end
            expect(last_response).to have_http_status :unauthorized
            expect(last_response.header["WWW-Authenticate"]).to eq('Bearer realm="OpenProject API" error="invalid_token" error_description="The access token audience claim is wrong"')
            expect(JSON.parse(last_response.body)).to eq(error_response_body)
          end
        end

        context "when aud contains client_id" do
          let(:token_aud) { ["master-realm", "account", "https://openproject.internal"] }

          it do
            Timecop.freeze(token_exp - 20.seconds) do
              get resource
            end
            expect(last_response).to have_http_status :ok
          end
        end
      end

      context "when access token has expired already" do
        it do
          Timecop.freeze(token_exp + 20.seconds) do
            get resource
          end

          expect(last_response).to have_http_status :unauthorized
          expect(last_response.header["WWW-Authenticate"]).to eq('Bearer realm="OpenProject API" error="invalid_token" error_description="The access token expired"')
          expect(JSON.parse(last_response.body)).to eq(error_response_body)
        end

        it "caches keys request to keycloak" do
          Timecop.freeze(token_exp + 20.seconds) do
            get resource
          end
          expect(last_response).to have_http_status :unauthorized

          Timecop.freeze(token_exp + 20.seconds) do
            get resource
          end
          expect(last_response).to have_http_status :unauthorized

          expect(keys_request_stub).to have_been_made.once
        end
      end

      context "when kid is absent in keycloak keys response" do
        let(:keys_hash) do
          { "keys" => [] }
        end

        it do
          Timecop.freeze(token_exp - 20.seconds) do
            get resource
          end
          expect(last_response).to have_http_status :unauthorized
          expect(JSON.parse(last_response.body)).to eq(error_response_body)
          expect(last_response.header["WWW-Authenticate"]).to eq('Bearer realm="OpenProject API" error="invalid_token" error_description="The access token signature kid is unknown"')
        end
      end
    end
  end
end
