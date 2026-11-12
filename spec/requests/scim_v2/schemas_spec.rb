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

RSpec.describe "SCIM API Schemas", with_ee: [:scim_api] do
  let(:oidc_provider_slug) { "keycloak" }
  let(:oidc_provider) { create(:oidc_provider, slug: oidc_provider_slug) }
  let(:headers) { { "CONTENT_TYPE" => "application/scim+json", "HTTP_AUTHORIZATION" => "Bearer #{token.plaintext_token}" } }
  let(:token) { create(:oauth_access_token, resource_owner: service_account, scopes: ["scim_v2"]) }
  let(:service_account) { create(:service_account, service: scim_client) }
  let(:scim_client) { create(:scim_client, authentication_method: :oauth2_token, auth_provider_id: oidc_provider.id) }

  before { token }

  describe "GET /scim_v2/Schemas" do
    it "responds with supported schemas" do
      get "/scim_v2/Schemas", {}, headers

      response_body = JSON.parse(last_response.body)
      expect(response_body["totalResults"]).to eq(2)
      expect(response_body["schemas"]).to eq(["urn:ietf:params:scim:api:messages:2.0:ListResponse"])
      group_schema = response_body["Resources"].find { |r| r["name"] == "Group" }
      user_schema = response_body["Resources"].find { |r| r["name"] == "User" }

      expect(group_schema).to eq(
        "name" => "Group",
        "id" => "urn:ietf:params:scim:schemas:core:2.0:Group",
        "description" => "Represents a Group",
        "meta" => { "resourceType" => "Schema",
                    "location" => "http://test.host/scim_v2/Schemas?name=urn%3Aietf%3Aparams%3Ascim%3Aschemas%3Acore%3A2.0%3AGroup" },
        "attributes" => [
          { "multiValued" => false,
            "required" => true,
            "caseExact" => false,
            "mutability" => "readWrite",
            "uniqueness" => "none",
            "returned" => "default",
            "name" => "displayName",
            "type" => "string" },
          { "multiValued" => true,
            "required" => false,
            "caseExact" => false,
            "mutability" => "readWrite",
            "uniqueness" => "none",
            "returned" => "default",
            "type" => "complex",
            "subAttributes" => [
              { "multiValued" => false,
                "required" => true,
                "caseExact" => false,
                "mutability" => "immutable",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "value",
                "type" => "string" },
              { "multiValued" => false,
                "required" => false,
                "caseExact" => false,
                "mutability" => "immutable",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "type",
                "type" => "string" },
              { "multiValued" => false,
                "required" => false,
                "caseExact" => false,
                "mutability" => "immutable",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "display",
                "type" => "string" }
            ],
            "name" => "members" },
          { "multiValued" => false,
            "required" => true,
            "caseExact" => true,
            "mutability" => "readWrite",
            "uniqueness" => "server",
            "returned" => "default",
            "name" => "externalId",
            "type" => "string" },
          { "multiValued" => false,
            "required" => false,
            "caseExact" => true,
            "mutability" => "readOnly",
            "uniqueness" => "server",
            "returned" => "default",
            "name" => "id",
            "type" => "string" }
        ]
      )
      expect(user_schema).to eq(
        "name" => "User",
        "id" => "urn:ietf:params:scim:schemas:core:2.0:User",
        "description" => "Represents a User",
        "meta" => { "resourceType" => "Schema",
                    "location" => "http://test.host/scim_v2/Schemas?name=urn%3Aietf%3Aparams%3Ascim%3Aschemas%3Acore%3A2.0%3AUser" },
        "attributes" => [
          { "multiValued" => false,
            "required" => true,
            "caseExact" => false,
            "mutability" => "readWrite",
            "uniqueness" => "server",
            "returned" => "default",
            "name" => "userName",
            "type" => "string" },
          { "multiValued" => false,
            "required" => true,
            "caseExact" => false,
            "mutability" => "readWrite",
            "uniqueness" => "none",
            "returned" => "default",
            "type" => "complex",
            "subAttributes" => [
              { "multiValued" => false,
                "required" => true,
                "caseExact" => false,
                "mutability" => "readWrite",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "familyName",
                "type" => "string" },
              { "multiValued" => false,
                "required" => true,
                "caseExact" => false,
                "mutability" => "readWrite",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "givenName",
                "type" => "string" }
            ],
            "name" => "name" },
          { "multiValued" => false,
            "required" => false,
            "caseExact" => false,
            "mutability" => "readWrite",
            "uniqueness" => "none",
            "returned" => "default",
            "name" => "active",
            "type" => "boolean" },
          { "multiValued" => true,
            "required" => true,
            "caseExact" => false,
            "mutability" => "readWrite",
            "uniqueness" => "none",
            "returned" => "default",
            "type" => "complex",
            "subAttributes" => [
              { "multiValued" => false,
                "required" => true,
                "caseExact" => false,
                "mutability" => "readWrite",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "value",
                "type" => "string" },
              { "multiValued" => false,
                "required" => false,
                "caseExact" => false,
                "mutability" => "readOnly",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "display",
                "type" => "string" },
              { "multiValued" => false,
                "required" => false,
                "caseExact" => false,
                "mutability" => "readWrite",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "type",
                "type" => "string" },
              { "multiValued" => false,
                "required" => false,
                "caseExact" => false,
                "mutability" => "readWrite",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "primary",
                "type" => "boolean" }
            ],
            "name" => "emails" },
          { "multiValued" => true,
            "required" => false,
            "caseExact" => false,
            "mutability" => "readOnly",
            "uniqueness" => "none",
            "returned" => "default",
            "type" => "complex",
            "subAttributes" => [
              { "multiValued" => false,
                "required" => true,
                "caseExact" => false,
                "mutability" => "readOnly",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "value",
                "type" => "string" },
              { "multiValued" => false,
                "required" => false,
                "caseExact" => false,
                "mutability" => "readOnly",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "display",
                "type" => "string" },
              { "multiValued" => false,
                "required" => false,
                "caseExact" => false,
                "mutability" => "readOnly",
                "uniqueness" => "none",
                "returned" => "default",
                "name" => "type",
                "type" => "string" }
            ],
            "name" => "groups" },
          { "multiValued" => false,
            "required" => true,
            "caseExact" => true,
            "mutability" => "readWrite",
            "uniqueness" => "server",
            "returned" => "default",
            "name" => "externalId",
            "type" => "string" },
          { "multiValued" => false,
            "required" => false,
            "caseExact" => true,
            "mutability" => "readOnly",
            "uniqueness" => "server",
            "returned" => "default",
            "name" => "id",
            "type" => "string" }
        ]
      )
    end
  end
end
