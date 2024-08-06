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
            "identifier" => "https://openproject.local",
            "secret" => "9AWjVC3A4U1HLrZuSP4xiwHfw6zmgECn",
            "host" => "keycloak.local",
            "issuer" => "https://keycloak.local/realms/master",
            "authorization_endpoint" => "/realms/master/protocol/openid-connect/auth",
            "token_endpoint" => "/realms/master/protocol/openid-connect/token",
            "userinfo_endpoint" => "/realms/master/protocol/openid-connect/userinfo",
            "end_session_endpoint" => "https://keycloak.local/realms/master/protocol/openid-connect/logout",
            "jwks_uri" => "https://keycloak.local/realms/master/protocol/openid-connect/certs"
          }
        }
      }
    }
  ) do
    let(:rsa_signed_access_token_without_aud) do
      "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI5N0FteXZvUzhCRkZSZm01ODVHUGdBMTZHMUgyVjIyRWR4eHVBWVV1b0trIn0.eyJleHAiOjE3MjEyODM0MzAsImlhdCI6MTcyMTI4MzM3MCwianRpIjoiYzUyNmI0MzUtOTkxZi00NzRhLWFkMWItYzM3MTQ1NmQxZmQwIiwiaXNzIjoiaHR0cHM6Ly9rZXljbG9hay5sb2NhbC9yZWFsbXMvbWFzdGVyIiwiYXVkIjpbIm1hc3Rlci1yZWFsbSIsImFjY291bnQiXSwic3ViIjoiYjcwZTJmYmYtZWE2OC00MjBjLWE3YTUtMGEyODdjYjY4OWM2IiwidHlwIjoiQmVhcmVyIiwiYXpwIjoiaHR0cHM6Ly9vcGVucHJvamVjdC5sb2NhbCIsInNlc3Npb25fc3RhdGUiOiJlYjIzNTI0MC0wYjQ3LTQ4ZmEtOGIzZS1mM2IzMTBkMzUyZTMiLCJhY3IiOiIxIiwiYWxsb3dlZC1vcmlnaW5zIjpbImh0dHBzOi8vb3BlbnByb2plY3QubG9jYWwiXSwicmVhbG1fYWNjZXNzIjp7InJvbGVzIjpbImNyZWF0ZS1yZWFsbSIsImRlZmF1bHQtcm9sZXMtbWFzdGVyIiwib2ZmbGluZV9hY2Nlc3MiLCJhZG1pbiIsInVtYV9hdXRob3JpemF0aW9uIl19LCJyZXNvdXJjZV9hY2Nlc3MiOnsibWFzdGVyLXJlYWxtIjp7InJvbGVzIjpbInZpZXctcmVhbG0iLCJ2aWV3LWlkZW50aXR5LXByb3ZpZGVycyIsIm1hbmFnZS1pZGVudGl0eS1wcm92aWRlcnMiLCJpbXBlcnNvbmF0aW9uIiwiY3JlYXRlLWNsaWVudCIsIm1hbmFnZS11c2VycyIsInF1ZXJ5LXJlYWxtcyIsInZpZXctYXV0aG9yaXphdGlvbiIsInF1ZXJ5LWNsaWVudHMiLCJxdWVyeS11c2VycyIsIm1hbmFnZS1ldmVudHMiLCJtYW5hZ2UtcmVhbG0iLCJ2aWV3LWV2ZW50cyIsInZpZXctdXNlcnMiLCJ2aWV3LWNsaWVudHMiLCJtYW5hZ2UtYXV0aG9yaXphdGlvbiIsIm1hbmFnZS1jbGllbnRzIiwicXVlcnktZ3JvdXBzIl19LCJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19LCJzY29wZSI6ImVtYWlsIHByb2ZpbGUiLCJzaWQiOiJlYjIzNTI0MC0wYjQ3LTQ4ZmEtOGIzZS1mM2IzMTBkMzUyZTMiLCJlbWFpbF92ZXJpZmllZCI6ZmFsc2UsInByZWZlcnJlZF91c2VybmFtZSI6ImFkbWluIn0.cLgbN9kygRwthUx0R0FazPfIUeEUVnw4HnDgN-Hsnm9oXVr6MqmfTRKEI-6n62dlnVKsdadF_tWf3jp26d6neLj1zlR-vojwaHm8A08S9m6IeMr9e0CGiYVHjrJtEeTgq6P9cJJfe7uuhSSvlG3ltFPDxaAe14Dz3BjhLO3iaCRkWfAZjKmnW-IMzzzHfGH-7of7qCAlF5ObEax38mf1Q0OmsPA4_5po-FFtw7H7FfDjsr6EXgtdwloDePkk2XIHs2XsIo0YugVHC9GqCWgBA8MBvCirFivqM53paZMnjhpQH-xgTpYGWlw3WNbG2Rny2GoEwIxdYOUO2amDQ_zkrQ"
    end
    let(:rsa_signed_access_token_with_aud) do
      "eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICI5N0FteXZvUzhCRkZSZm01ODVHUGdBMTZHMUgyVjIyRWR4eHVBWVV1b0trIn0.eyJleHAiOjE3MjEyODQ3NjksImlhdCI6MTcyMTI4NDcwOSwianRpIjoiNjhiYzNmZTMtNDFhZi00MGUwLTg4NGEtNDgxNTM1MTU3NjIyIiwiaXNzIjoiaHR0cHM6Ly9rZXljbG9hay5sb2NhbC9yZWFsbXMvbWFzdGVyIiwiYXVkIjpbImh0dHBzOi8vb3BlbnByb2plY3QubG9jYWwiLCJtYXN0ZXItcmVhbG0iLCJhY2NvdW50Il0sInN1YiI6ImI3MGUyZmJmLWVhNjgtNDIwYy1hN2E1LTBhMjg3Y2I2ODljNiIsInR5cCI6IkJlYXJlciIsImF6cCI6Imh0dHBzOi8vb3BlbnByb2plY3QubG9jYWwiLCJzZXNzaW9uX3N0YXRlIjoiNWI5OWM3M2EtY2QwNS00N2MwLTgwZTctODRjYTNiYTI0MDQ1IiwiYWNyIjoiMSIsImFsbG93ZWQtb3JpZ2lucyI6WyJodHRwczovL29wZW5wcm9qZWN0LmxvY2FsIl0sInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJjcmVhdGUtcmVhbG0iLCJkZWZhdWx0LXJvbGVzLW1hc3RlciIsIm9mZmxpbmVfYWNjZXNzIiwiYWRtaW4iLCJ1bWFfYXV0aG9yaXphdGlvbiJdfSwicmVzb3VyY2VfYWNjZXNzIjp7Im1hc3Rlci1yZWFsbSI6eyJyb2xlcyI6WyJ2aWV3LXJlYWxtIiwidmlldy1pZGVudGl0eS1wcm92aWRlcnMiLCJtYW5hZ2UtaWRlbnRpdHktcHJvdmlkZXJzIiwiaW1wZXJzb25hdGlvbiIsImNyZWF0ZS1jbGllbnQiLCJtYW5hZ2UtdXNlcnMiLCJxdWVyeS1yZWFsbXMiLCJ2aWV3LWF1dGhvcml6YXRpb24iLCJxdWVyeS1jbGllbnRzIiwicXVlcnktdXNlcnMiLCJtYW5hZ2UtZXZlbnRzIiwibWFuYWdlLXJlYWxtIiwidmlldy1ldmVudHMiLCJ2aWV3LXVzZXJzIiwidmlldy1jbGllbnRzIiwibWFuYWdlLWF1dGhvcml6YXRpb24iLCJtYW5hZ2UtY2xpZW50cyIsInF1ZXJ5LWdyb3VwcyJdfSwiYWNjb3VudCI6eyJyb2xlcyI6WyJtYW5hZ2UtYWNjb3VudCIsIm1hbmFnZS1hY2NvdW50LWxpbmtzIiwidmlldy1wcm9maWxlIl19fSwic2NvcGUiOiJlbWFpbCBwcm9maWxlIiwic2lkIjoiNWI5OWM3M2EtY2QwNS00N2MwLTgwZTctODRjYTNiYTI0MDQ1IiwiZW1haWxfdmVyaWZpZWQiOmZhbHNlLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJhZG1pbiJ9.WS2TWDHFU2Amglj6j4LYhsUY5oyw3J7PhllGf0MH3Kz_ETT7GZCR6MvtvY1EuOb11t_YKrQ6M8LBHhh5j9mrFNrg-vTXMaYmXwXCQxfKtHvTVbo4coEPpnW_8NEVBG8dvduLRVK_o7BbNhZH9FCe5sb_7EbA18E7evHNLWi9co4nLsSBQSeBoHRSJqD28Yr2Xj1u618bVz_grAlm0DiwhJhGzkv-JJtUGa1xQyIkNeogPWalnLpzspa2Q2i5LeLB02aoPDlQ_PkUF6Tn6IGY2for8HQQlYkjBvhxL_wMBDoNRKlFycqkCBSedsPx2m6NdmBK8ppLgaMfKe0uVGvaTg"
    end
    let(:token_exp) { Time.zone.at(JWT.decode(token, nil, false)[0]["exp"]) }
    let(:token_sub) { JWT.decode(token, nil, false)[0]["sub"] }
    let(:expected_message) { "You did not provide the correct credentials." }
    let(:keys_request_stub) { nil }

    before do
      create(:user, identity_url: "keycloak:#{token_sub}")
      keys_request_stub

      header "Authorization", "Bearer #{token}"
    end

    context "when token is issued by provider not configured in OP" do
      let(:token) do
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJpc3MiOiJpc3N1ZXIuY29tIn0.C9gEPaqdNSEZ4dZHz0z51VCylScIEqRLnwMCkNXuz6g"
      end

      it do
        get resource
        expect(last_response).to have_http_status :unauthorized
        expect(last_response.header["WWW-Authenticate"]).to eq("Bearer realm=\"OpenProject API\" error=\"invalid_token\" error_description=\"The access token issuer is unknown\"")
        expect(JSON.parse(last_response.body)).to eq(error_response_body)
      end
    end

    context "when token is issued by provider configured in OP" do
      context "when token signature algorithm is not supported" do
        let(:token) do
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJpc3MiOiJodHRwczovL2tleWNsb2FrLmxvY2FsL3JlYWxtcy9tYXN0ZXIifQ.Pwod8ZJqq3jWsbnrGw4ZU1-aLS2bSicb8PgiF78JHUc"
        end

        it do
          get resource
          expect(last_response).to have_http_status :unauthorized
          expect(last_response.header["WWW-Authenticate"]).to eq("Bearer realm=\"OpenProject API\" error=\"invalid_token\" error_description=\"Token signature algorithm is not supported\"")
          expect(JSON.parse(last_response.body)).to eq(error_response_body)
        end
      end

      context "when kid is present" do
        let(:keys_request_stub) do
          stub_request(:get, "https://keycloak.local/realms/master/protocol/openid-connect/certs")
            .with(
              headers: {
                "Accept" => "*/*",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "User-Agent" => "JSON::JWK::Set::Fetcher 2.7.2"
              }
            )
            .to_return(status: 200, body: '{"keys":[{"kid":"CANAG6lJUPKqKDoWxxXL5wAHf2U18BAzm_LJm7RPTGk","kty":"RSA","alg":"RSA-OAEP","use":"enc","n":"nqJexS6n-SxKSDUxXp_dsNwDW6cZ4Rtgqq9ut_lp1CNSph5wTnLG3aQQsTEvx5o3-SZ-pHjJ0gtEpg7clAz-w-YQyZoAXkFtQqmZJxsmdS4K0yILxO3WUNdJQlutjmq-Ri50Senn5IV7yEYWLo8St1qzUqWZhp0HKudyty24triC9UJTK03W3_Tr5c1X8vKL8duAjvLB7p_sYUOrnLq5pD5lqwxVSAiN8qS5zVNZMrhGV5aN1vN_vue_tw8c2SVOCLLTrUh3441rYaeo-UwQZF7ZTm30xflqAIfe8qMoB20wtWYAXR0D5iqkkdEH4XanCYVm5vdUFIPPvXZhRDWoNQ","e":"AQAB","x5c":["MIICmzCCAYMCBgGQupeGPzANBgkqhkiG9w0BAQsFADARMQ8wDQYDVQQDDAZtYXN0ZXIwHhcNMjQwNzE2MDgwODMwWhcNMzQwNzE2MDgxMDEwWjARMQ8wDQYDVQQDDAZtYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCeol7FLqf5LEpINTFen92w3ANbpxnhG2Cqr263+WnUI1KmHnBOcsbdpBCxMS/Hmjf5Jn6keMnSC0SmDtyUDP7D5hDJmgBeQW1CqZknGyZ1LgrTIgvE7dZQ10lCW62Oar5GLnRJ6efkhXvIRhYujxK3WrNSpZmGnQcq53K3Lbi2uIL1QlMrTdbf9OvlzVfy8ovx24CO8sHun+xhQ6ucurmkPmWrDFVICI3ypLnNU1kyuEZXlo3W83++57+3DxzZJU4IstOtSHfjjWthp6j5TBBkXtlObfTF+WoAh97yoygHbTC1ZgBdHQPmKqSR0QfhdqcJhWbm91QUg8+9dmFENag1AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAB/AGvP0gviPoJszj/oQgBsMpPGRHLpnTmrXnTaa7Xk2sgExAb4zUAwxGjtR347t697cpiKQYBkR2ndswnt93Sx/Ot+yn5BdYcNvZuEh5jb5bkH2V4h6/LrYljTymby+XPBEf+XLhBOjoI3SKtNJk4pEqVNwLuKKbObqJcE3G3VBVSdzRUcIrjZr7yAQeLnhczS3hJ0Ct6Y7S5Q6DK+/PU1+AvlW+7GfzpRMqVfLcqhNpRwdCVGlJYKaUJfIe1vav10D94xA0U1sKex3iA1S+1HlS2BCWx/0rXwgcquMpUZlOAKiT0K6SIFxBFFnM9eQbF97Dz7Bzw+jyqStGUcH9YA="],"x5t":"TuBfrOL00KXDrOWTv3jw7Uxx3hA","x5t#S256":"7su5lOXF5qcMuvp44ynsoyk3B0l9Sr_bOVlg768shpY"},{"kid":"97AmyvoS8BFFRfm585GPgA16G1H2V22EdxxuAYUuoKk","kty":"RSA","alg":"RS256","use":"sig","n":"jMB2r7BG4QJzLnA2_fgG1mxlh2RX_MSx0lc2lrPIVFGYBuAu8irwRLSexX5aQdD_AtnxLD4g9jiG6VEDwmWopEe0fr-QMl0IiES5tJuQMrjhajOkzr8xTYu6zl-knL0tu99iRbmKNYzEcv0TAgY_95n4gD5tPhYvY4gXuHrFKqYkJQPsSgoThlH7hAtfzsDt6yp3P2lQUESGg3pzc_J_NKnQkkggcNB06Hlz4DmcHxhWXK51P1V9cE7qh4PrhsJ-SOH5grcN9PtOZi6f2VlWdFdyisT-YehNklfVqBtdCLm7Ocghhl0HSgLuV-9dHCdwBLUpABsdsd0L3LRCUgRfjQ","e":"AQAB","x5c":["MIICmzCCAYMCBgGQupeFFTANBgkqhkiG9w0BAQsFADARMQ8wDQYDVQQDDAZtYXN0ZXIwHhcNMjQwNzE2MDgwODMwWhcNMzQwNzE2MDgxMDEwWjARMQ8wDQYDVQQDDAZtYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCMwHavsEbhAnMucDb9+AbWbGWHZFf8xLHSVzaWs8hUUZgG4C7yKvBEtJ7FflpB0P8C2fEsPiD2OIbpUQPCZaikR7R+v5AyXQiIRLm0m5AyuOFqM6TOvzFNi7rOX6ScvS2732JFuYo1jMRy/RMCBj/3mfiAPm0+Fi9jiBe4esUqpiQlA+xKChOGUfuEC1/OwO3rKnc/aVBQRIaDenNz8n80qdCSSCBw0HToeXPgOZwfGFZcrnU/VX1wTuqHg+uGwn5I4fmCtw30+05mLp/ZWVZ0V3KKxP5h6E2SV9WoG10Iubs5yCGGXQdKAu5X710cJ3AEtSkAGx2x3QvctEJSBF+NAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAIoBCsOO0bXiVspoXkqdOts4+3sULbbp5aEwQscmLX017Zvv5jxdkZxUYk8L08lNB+WlC1ES4VlmtE06D0cWYErGpArJzVBKgYSA3CkA9veBEugHviMqfwg3suNc8S+GtaRBvpbVZtXydjjqA8GZ4eKhPoJLHHCX6X2Ad33Cdt0/ftucjTqAKVzzzgWZejy+ZKP6ybAqYJ+EZoPUXlyWT3uwcpGEJ3nzOYYGTfxOSmAwnH2v5Z/JWr9ex5o/+QBuBhFcg0z8NcHa3Z0E6ZC9GGxV7XztBqYicO+nONHTLCctoJmyXvLM4j8qIG2UQgPIiwIL0Jkz6xQAYyXvsb+LhM8="],"x5t":"BFrni6MoX-CJwtMT4vzij1HBSTI","x5t#S256":"-Ge3y4JRezxhGTDfbkNoz7prkokzYtbKQ9ardPtfcz4"}]}', headers: {})
        end

        context "when access token has not expired yet" do
          context "when aud does not contain client_id" do
            let(:token) { rsa_signed_access_token_without_aud }

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
            let(:token) { rsa_signed_access_token_with_aud }

            it do
              Timecop.freeze(token_exp - 20.seconds) do
                get resource
              end
              expect(last_response).to have_http_status :ok
            end
          end
        end

        context "when access token has expired already" do
          let(:token) { rsa_signed_access_token_without_aud }

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
      end

      context "when kid is absent in keycloak keys response" do
        let(:keys_request_stub) do
          stub_request(:get, "https://keycloak.local/realms/master/protocol/openid-connect/certs")
            .with(
              headers: {
                "Accept" => "*/*",
                "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
                "User-Agent" => "JSON::JWK::Set::Fetcher 2.7.2"
              }
            )
            .to_return(status: 200, body: '{"keys":[{"kid":"CANAG6lJUPKqKDoWxxXL5wAHf2U18BAzm_LJm7RPTGk","kty":"RSA","alg":"RSA-OAEP","use":"enc","n":"nqJexS6n-SxKSDUxXp_dsNwDW6cZ4Rtgqq9ut_lp1CNSph5wTnLG3aQQsTEvx5o3-SZ-pHjJ0gtEpg7clAz-w-YQyZoAXkFtQqmZJxsmdS4K0yILxO3WUNdJQlutjmq-Ri50Senn5IV7yEYWLo8St1qzUqWZhp0HKudyty24triC9UJTK03W3_Tr5c1X8vKL8duAjvLB7p_sYUOrnLq5pD5lqwxVSAiN8qS5zVNZMrhGV5aN1vN_vue_tw8c2SVOCLLTrUh3441rYaeo-UwQZF7ZTm30xflqAIfe8qMoB20wtWYAXR0D5iqkkdEH4XanCYVm5vdUFIPPvXZhRDWoNQ","e":"AQAB","x5c":["MIICmzCCAYMCBgGQupeGPzANBgkqhkiG9w0BAQsFADARMQ8wDQYDVQQDDAZtYXN0ZXIwHhcNMjQwNzE2MDgwODMwWhcNMzQwNzE2MDgxMDEwWjARMQ8wDQYDVQQDDAZtYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCeol7FLqf5LEpINTFen92w3ANbpxnhG2Cqr263+WnUI1KmHnBOcsbdpBCxMS/Hmjf5Jn6keMnSC0SmDtyUDP7D5hDJmgBeQW1CqZknGyZ1LgrTIgvE7dZQ10lCW62Oar5GLnRJ6efkhXvIRhYujxK3WrNSpZmGnQcq53K3Lbi2uIL1QlMrTdbf9OvlzVfy8ovx24CO8sHun+xhQ6ucurmkPmWrDFVICI3ypLnNU1kyuEZXlo3W83++57+3DxzZJU4IstOtSHfjjWthp6j5TBBkXtlObfTF+WoAh97yoygHbTC1ZgBdHQPmKqSR0QfhdqcJhWbm91QUg8+9dmFENag1AgMBAAEwDQYJKoZIhvcNAQELBQADggEBAB/AGvP0gviPoJszj/oQgBsMpPGRHLpnTmrXnTaa7Xk2sgExAb4zUAwxGjtR347t697cpiKQYBkR2ndswnt93Sx/Ot+yn5BdYcNvZuEh5jb5bkH2V4h6/LrYljTymby+XPBEf+XLhBOjoI3SKtNJk4pEqVNwLuKKbObqJcE3G3VBVSdzRUcIrjZr7yAQeLnhczS3hJ0Ct6Y7S5Q6DK+/PU1+AvlW+7GfzpRMqVfLcqhNpRwdCVGlJYKaUJfIe1vav10D94xA0U1sKex3iA1S+1HlS2BCWx/0rXwgcquMpUZlOAKiT0K6SIFxBFFnM9eQbF97Dz7Bzw+jyqStGUcH9YA="],"x5t":"TuBfrOL00KXDrOWTv3jw7Uxx3hA","x5t#S256":"7su5lOXF5qcMuvp44ynsoyk3B0l9Sr_bOVlg768shpY"},{"kid":"9755555S8BFFRfm585GPgA16G1H2V22EdxxuAYUuoKk","kty":"RSA","alg":"RS256","use":"sig","n":"jMB2r7BG4QJzLnA2_fgG1mxlh2RX_MSx0lc2lrPIVFGYBuAu8irwRLSexX5aQdD_AtnxLD4g9jiG6VEDwmWopEe0fr-QMl0IiES5tJuQMrjhajOkzr8xTYu6zl-knL0tu99iRbmKNYzEcv0TAgY_95n4gD5tPhYvY4gXuHrFKqYkJQPsSgoThlH7hAtfzsDt6yp3P2lQUESGg3pzc_J_NKnQkkggcNB06Hlz4DmcHxhWXK51P1V9cE7qh4PrhsJ-SOH5grcN9PtOZi6f2VlWdFdyisT-YehNklfVqBtdCLm7Ocghhl0HSgLuV-9dHCdwBLUpABsdsd0L3LRCUgRfjQ","e":"AQAB","x5c":["MIICmzCCAYMCBgGQupeFFTANBgkqhkiG9w0BAQsFADARMQ8wDQYDVQQDDAZtYXN0ZXIwHhcNMjQwNzE2MDgwODMwWhcNMzQwNzE2MDgxMDEwWjARMQ8wDQYDVQQDDAZtYXN0ZXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCMwHavsEbhAnMucDb9+AbWbGWHZFf8xLHSVzaWs8hUUZgG4C7yKvBEtJ7FflpB0P8C2fEsPiD2OIbpUQPCZaikR7R+v5AyXQiIRLm0m5AyuOFqM6TOvzFNi7rOX6ScvS2732JFuYo1jMRy/RMCBj/3mfiAPm0+Fi9jiBe4esUqpiQlA+xKChOGUfuEC1/OwO3rKnc/aVBQRIaDenNz8n80qdCSSCBw0HToeXPgOZwfGFZcrnU/VX1wTuqHg+uGwn5I4fmCtw30+05mLp/ZWVZ0V3KKxP5h6E2SV9WoG10Iubs5yCGGXQdKAu5X710cJ3AEtSkAGx2x3QvctEJSBF+NAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAIoBCsOO0bXiVspoXkqdOts4+3sULbbp5aEwQscmLX017Zvv5jxdkZxUYk8L08lNB+WlC1ES4VlmtE06D0cWYErGpArJzVBKgYSA3CkA9veBEugHviMqfwg3suNc8S+GtaRBvpbVZtXydjjqA8GZ4eKhPoJLHHCX6X2Ad33Cdt0/ftucjTqAKVzzzgWZejy+ZKP6ybAqYJ+EZoPUXlyWT3uwcpGEJ3nzOYYGTfxOSmAwnH2v5Z/JWr9ex5o/+QBuBhFcg0z8NcHa3Z0E6ZC9GGxV7XztBqYicO+nONHTLCctoJmyXvLM4j8qIG2UQgPIiwIL0Jkz6xQAYyXvsb+LhM8="],"x5t":"BFrni6MoX-CJwtMT4vzij1HBSTI","x5t#S256":"-Ge3y4JRezxhGTDfbkNoz7prkokzYtbKQ9ardPtfcz4"}]}', headers: {})
        end
        let(:token) { rsa_signed_access_token_with_aud }

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
