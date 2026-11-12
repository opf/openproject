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

RSpec.describe "SCIM API Authentication" do
  let(:oidc_provider_slug) { "keycloak" }
  let(:oidc_provider) { create(:oidc_provider, slug: oidc_provider_slug) }
  let(:headers) { { "CONTENT_TYPE" => "application/scim+json", "HTTP_AUTHORIZATION" => "Bearer #{token}" } }
  let(:service_account) { create(:service_account, service: scim_client) }
  let(:scim_client) { create(:scim_client, authentication_method: :oauth2_token, auth_provider_id: oidc_provider.id) }

  describe "GET /scim_v2/ServiceProviderConfig" do
    context "with enterprise feature enabled", with_ee: [:scim_api] do
      context "with static token" do
        let(:oauth_access_token) { create(:oauth_access_token, resource_owner: service_account, scopes: ["scim_v2"]) }
        let!(:token) { oauth_access_token.plaintext_token }

        it do
          get "/scim_v2/ServiceProviderConfig", {}, headers
          expect(last_response).to have_http_status(200)
        end
      end

      context "with JWT token", :webmock do
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
        let(:token_scope) { "scim_v2" }
        let(:expected_message) { "You did not provide the correct credentials." }
        let(:keys_request_stub) do
          stub_request(:get, "https://keycloak.local/realms/master/protocol/openid-connect/certs")
            .to_return(status: 200, body: JWT::JWK::Set.new(jwk_response).export.to_json, headers: {})
        end
        let(:jwk_response) { jwk }

        before do
          service_account.user_auth_provider_links.create!(
            external_id: token_sub,
            auth_provider: oidc_provider
          )
          keys_request_stub

          header "Authorization", "Bearer #{token}"
        end

        it do
          get "/scim_v2/ServiceProviderConfig", {}, headers

          expect(last_response).to have_http_status(200)
        end

        context "when scim_v2 scope is missing in token" do
          let(:token_scope) { "api_v3" }
          let(:expected_www_auth_header) do
            'Bearer realm="OpenProject API", resource_metadata="http://test.host/.well-known/oauth-protected-resource", ' \
              'scope="scim_v2", error="insufficient_scope", ' \
              'error_description="Requires scope scim_v2 to access this resource."'
          end

          it do
            get "/scim_v2/ServiceProviderConfig", {}, headers
            expect(last_response.body).to eq("insufficient_scope")
            expect(last_response.headers["WWW-Authenticate"]).to eq(expected_www_auth_header)
            expect(last_response).to have_http_status(401)
          end
        end

        context "when token_sub does not match a service_account" do
          let(:expected_www_auth_header) do
            'Bearer realm="OpenProject API", resource_metadata="http://test.host/.well-known/oauth-protected-resource", ' \
              'scope="scim_v2", error="invalid_token", ' \
              'error_description="The user identified by the token is not known"'
          end

          before { service_account.user_auth_provider_links.delete_all }

          it do
            get "/scim_v2/ServiceProviderConfig", {}, headers

            expect(last_response).to have_http_status(401)
            expect(last_response.body).to eq("invalid_token")
            expect(last_response.headers["WWW-Authenticate"]).to eq(expected_www_auth_header)
          end
        end
      end
    end

    context "with the enterprise feature missing" do
      let(:oauth_access_token) { create(:oauth_access_token, resource_owner: service_account, scopes: ["scim_v2"]) }
      let!(:token) { oauth_access_token.plaintext_token }

      it do
        get "/scim_v2/ServiceProviderConfig", {}, headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          { "detail" => "This endpoint requires an enterprise subscription of at least corporate",
            "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
            "status" => "403" }
        )
        expect(last_response).to have_http_status(403)
      end
    end
  end
end
