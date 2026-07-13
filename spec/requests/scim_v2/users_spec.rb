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

RSpec.describe "SCIM API Users", with_ee: [:scim_api] do
  let(:external_user_id) { "idp_user_id_123asdqwe12345" }
  let(:external_group_id) { "idp_group_id_123asdqwe12345" }
  let(:external_admin_id) { "idp_admin_id_123asdqwe12345" }
  let(:oidc_provider_slug) { "keycloak" }
  let(:oidc_provider) { create(:oidc_provider, slug: oidc_provider_slug) }
  let(:admin) { create(:admin, identity_url: "#{oidc_provider.slug}:#{external_admin_id}") }
  let(:user) { create(:user, identity_url: "#{oidc_provider.slug}:#{external_user_id}") }
  let(:group) { create(:group, identity_url: "#{oidc_provider.slug}:#{external_group_id}", members: [user]) }
  let(:headers) { { "CONTENT_TYPE" => "application/scim+json", "HTTP_AUTHORIZATION" => "Bearer #{token.plaintext_token}" } }
  let(:token) { create(:oauth_access_token, resource_owner: service_account, scopes: ["scim_v2"]) }
  let(:service_account) { create(:service_account, service: scim_client, admin: true) }
  let(:scim_client) { create(:scim_client, authentication_method: :oauth2_token, auth_provider_id: oidc_provider.id) }

  before { token }

  describe "GET /scim_v2/Users" do
    before do
      admin
      group
    end

    it "responds with users list including locked(not_active users) and excluding users marked for deletion" do
      user_marked_for_deletion = create(:user_marked_for_deletion)
      locked_user = create(:locked_user)

      get "/scim_v2/Users", {}, headers

      response_body = JSON.parse(last_response.body)
      ids = response_body["Resources"].pluck("id")
      expect(ids).to include(locked_user.id.to_s)
      expect(response_body["Resources"].find { |resource| resource["id"] == locked_user.id.to_s }["active"]).to be(false)
      expect(ids).not_to include(user_marked_for_deletion.id.to_s)
      expect(response_body).to match("Resources" => include({ "active" => true,
                                                              "emails" => [{ "primary" => true,
                                                                             "type" => "work",
                                                                             "value" => admin.mail }],
                                                              "groups" => [],
                                                              "externalId" => external_admin_id,
                                                              "id" => admin.id.to_s,
                                                              "meta" => { "created" => admin.created_at.iso8601,
                                                                          "lastModified" => admin.updated_at.iso8601,
                                                                          "location" => "http://test.host/scim_v2/Users/#{admin.id}",
                                                                          "resourceType" => "User" },
                                                              "name" => { "familyName" => admin.lastname,
                                                                          "givenName" => admin.firstname },
                                                              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                              "userName" => admin.login },
                                                            { "active" => true,
                                                              "emails" => [{ "primary" => true,
                                                                             "type" => "work",
                                                                             "value" => user.mail }],
                                                              "externalId" => external_user_id,
                                                              "groups" => [{ "value" => group.id.to_s }],
                                                              "id" => user.id.to_s,
                                                              "meta" => { "created" => user.created_at.iso8601,
                                                                          "lastModified" => user.updated_at.iso8601,
                                                                          "location" => "http://test.host/scim_v2/Users/#{user.id}",
                                                                          "resourceType" => "User" },
                                                              "name" => { "familyName" => user.lastname,
                                                                          "givenName" => user.firstname },
                                                              "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                              "userName" => user.login }),
                                     "itemsPerPage" => 100,
                                     "schemas" => ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
                                     "startIndex" => 1,
                                     "totalResults" => 5)
    end

    it "lists each user once when they belong to multiple groups and includes all groups" do
      second_group = create(:group,
                            identity_url: "#{oidc_provider.slug}:idp_group_second_membership",
                            members: [user])

      get "/scim_v2/Users", {}, headers

      response_body = JSON.parse(last_response.body)
      resource_ids = response_body["Resources"].pluck("id")
      expect(resource_ids.uniq).to eq(resource_ids)

      user_resources = response_body["Resources"].select { |item| item["id"] == user.id.to_s }
      expect(user_resources.length).to eq(1)

      group_values = user_resources.first["groups"].pluck("value")
      expect(group_values).to contain_exactly(group.id.to_s, second_group.id.to_s)
    end

    it "filters results by familyName case-insensitively" do
      expected_body = { "Resources" => [{ "active" => true,
                                          "emails" => [{ "primary" => true,
                                                         "type" => "work",
                                                         "value" => user.mail }],
                                          "externalId" => external_user_id,
                                          "groups" => [{ "value" => group.id.to_s }],
                                          "id" => user.id.to_s,
                                          "meta" => { "created" => user.created_at.iso8601,
                                                      "lastModified" => user.updated_at.iso8601,
                                                      "location" => "http://test.host/scim_v2/Users/#{user.id}",
                                                      "resourceType" => "User" },
                                          "name" => { "familyName" => user.lastname,
                                                      "givenName" => user.firstname },
                                          "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                          "userName" => user.login }],
                        "itemsPerPage" => 100,
                        "schemas" => ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
                        "startIndex" => 1,
                        "totalResults" => 1 }
      filter_with_existing_rows = ERB::Util.url_encode("familyName Eq \"#{user.lastname.upcase}\"")
      get "/scim_v2/Users?filter=#{filter_with_existing_rows}", {}, headers

      response_body = JSON.parse(last_response.body)
      expect(response_body).to eq(expected_body)

      filter_with_existing_rows = ERB::Util.url_encode("familyName Eq \"#{user.lastname.downcase}\"")
      get "/scim_v2/Users?filter=#{filter_with_existing_rows}", {}, headers

      response_body = JSON.parse(last_response.body)
      expect(response_body).to eq(expected_body)

      filter_with_nonexisting_rows = ERB::Util.url_encode('familyName Eq "NONEXISTENT USER LASTNAME"')
      get "/scim_v2/Users?filter=#{filter_with_nonexisting_rows}", {}, headers

      response_body = JSON.parse(last_response.body)
      expect(response_body).to eq("Resources" => [],
                                  "itemsPerPage" => 100,
                                  "schemas" => ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
                                  "startIndex" => 1,
                                  "totalResults" => 0)
    end

    it "filters results by externalId case-sesitively" do
      filter_with_existing_rows = ERB::Util.url_encode("externalId Eq \"#{external_user_id}\"")
      get "/scim_v2/Users?filter=#{filter_with_existing_rows}", {}, headers

      response_body = JSON.parse(last_response.body)
      expect(response_body).to eq("Resources" => [{ "active" => true,
                                                    "emails" => [{ "primary" => true,
                                                                   "type" => "work",
                                                                   "value" => user.mail }],
                                                    "externalId" => external_user_id,
                                                    "groups" => [{ "value" => group.id.to_s }],
                                                    "id" => user.id.to_s,
                                                    "meta" => { "created" => user.created_at.iso8601,
                                                                "lastModified" => user.updated_at.iso8601,
                                                                "location" => "http://test.host/scim_v2/Users/#{user.id}",
                                                                "resourceType" => "User" },
                                                    "name" => { "familyName" => user.lastname,
                                                                "givenName" => user.firstname },
                                                    "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                                    "userName" => user.login }],
                                  "itemsPerPage" => 100,
                                  "schemas" => ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
                                  "startIndex" => 1,
                                  "totalResults" => 1)

      filter_with_nonexisting_rows = ERB::Util.url_encode("externalId Eq \"#{external_user_id.upcase}\"")
      get "/scim_v2/Users?filter=#{filter_with_nonexisting_rows}", {}, headers

      response_body = JSON.parse(last_response.body)
      expect(response_body).to eq("Resources" => [],
                                  "itemsPerPage" => 100,
                                  "schemas" => ["urn:ietf:params:scim:api:messages:2.0:ListResponse"],
                                  "startIndex" => 1,
                                  "totalResults" => 0)
    end
  end

  describe "GET /scim_v2/Users/:id" do
    it "returns specific user data" do
      group
      get "/scim_v2/Users/#{user.id}", {}, headers

      response_body = JSON.parse(last_response.body)
      expect(response_body).to eq("active" => true,
                                  "emails" => [{ "primary" => true,
                                                 "type" => "work",
                                                 "value" => user.mail }],
                                  "externalId" => external_user_id,
                                  "groups" => [{ "value" => group.id.to_s }],
                                  "id" => user.id.to_s,
                                  "meta" => { "created" => user.created_at.iso8601,
                                              "lastModified" => user.updated_at.iso8601,
                                              "location" => "http://test.host/scim_v2/Users/#{user.id}",
                                              "resourceType" => "User" },
                                  "name" => { "familyName" => user.lastname,
                                              "givenName" => user.firstname },
                                  "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                  "userName" => user.login)
    end
  end

  describe "POST /scim_v2/Users/" do
    before { oidc_provider }

    context "when user with userName has already exists" do
      it "responds with uniqueness error" do
        group
        request_body = {
          "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
          "externalId" => external_user_id,
          "userName" => user.login,
          "name" => {
            "givenName" => "John",
            "familyName" => "Doe"
          },
          "active" => true,
          "emails" => [{
            "value" => "jdoe@example.com",
            "type" => "work",
            "primary" => true
          }]
        }

        post "/scim_v2/Users/", request_body.to_json, headers

        expect(last_response).to have_http_status(409)
        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
          "detail" => "Operation failed due to a uniqueness constraint: Username has already been taken.",
          "status" => "409",
          "scimType" => "uniqueness"
        )
      end
    end

    it "responds with 400 when email is missing" do
      group
      request_body = {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "externalId" => external_user_id,
        "userName" => "NewUserName",
        "name" => {
          "givenName" => "John",
          "familyName" => "Doe"
        },
        "active" => true,
        "emails" => []
      }

      post "/scim_v2/Users/", request_body.to_json, headers

      expect(last_response).to have_http_status(400)
      response_body = JSON.parse(last_response.body)
      expect(response_body).to eq(
        "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
        "detail" => "Invalid resource: Emails is required.",
        "status" => "400",
        "scimType" => "invalidValue"
      )
    end

    it "responds with 400 when familyName is missing" do
      group
      request_body = {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "externalId" => external_user_id,
        "userName" => "NewUserName",
        "name" => {
          "givenName" => "John"
        },
        "active" => true,
        "emails" => [
          {
            "value" => "jdoe@example.com",
            "type" => "work",
            "primary" => true
          }
        ]
      }

      post "/scim_v2/Users/", request_body.to_json, headers

      expect(last_response).to have_http_status(400)
      response_body = JSON.parse(last_response.body)
      expect(response_body).to eq(
        "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
        "detail" => "Invalid resource: Name familyname is required.",
        "status" => "400",
        "scimType" => "invalidValue"
      )
    end

    it "creates user with provided data and excludes some attributes" do
      request_body = {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "externalId" => external_user_id,
        "userName" => "jdoe",
        "name" => {
          "givenName" => "John",
          "familyName" => "Doe"
        },
        "active" => true,
        "emails" => [
          {
            "value" => "jdoe@example.com",
            "type" => "work",
            "primary" => true
          }
        ]
      }
      post "/scim_v2/Users/?excludedAttributes=emails,name.givenName", request_body.to_json, headers

      response_body = JSON.parse(last_response.body)
      created_user = User.find_by(login: "jdoe")
      expect(created_user).to be_present
      expect(response_body).to eq("active" => true,
                                  "externalId" => external_user_id,
                                  "groups" => [],
                                  "id" => created_user.id.to_s,
                                  "meta" => { "created" => created_user.created_at.iso8601,
                                              "lastModified" => created_user.updated_at.iso8601,
                                              "location" => "http://test.host/scim_v2/Users/#{created_user.id}",
                                              "resourceType" => "User" },
                                  "name" => { "familyName" => "Doe" },
                                  "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                  "userName" => "jdoe")
    end

    it "creates user with provided data" do
      request_body = {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "externalId" => external_user_id,
        "userName" => "jdoe",
        "name" => {
          "givenName" => "John",
          "familyName" => "Doe"
        },
        "active" => true,
        "emails" => [
          {
            "value" => "jdoe@example.com",
            "type" => "work",
            "primary" => true
          }
        ]
      }
      post "/scim_v2/Users/", request_body.to_json, headers

      response_body = JSON.parse(last_response.body)
      created_user = User.find_by(login: "jdoe")
      expect(created_user).to be_present
      expect(response_body).to eq("active" => true,
                                  "emails" => [{ "primary" => true,
                                                 "type" => "work",
                                                 "value" => "jdoe@example.com" }],
                                  "externalId" => external_user_id,
                                  "groups" => [],
                                  "id" => created_user.id.to_s,
                                  "meta" => { "created" => created_user.created_at.iso8601,
                                              "lastModified" => created_user.updated_at.iso8601,
                                              "location" => "http://test.host/scim_v2/Users/#{created_user.id}",
                                              "resourceType" => "User" },
                                  "name" => { "familyName" => "Doe",
                                              "givenName" => "John" },
                                  "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                  "userName" => "jdoe")
    end

    it "creates user with any email type string provided" do
      request_body = {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "externalId" => external_user_id,
        "userName" => "jdoe",
        "name" => {
          "givenName" => "John",
          "familyName" => "Doe"
        },
        "active" => true,
        "emails" => [
          {
            "value" => "jdoe@example.com",
            "type" => "untyped"
          }
        ]
      }
      post "/scim_v2/Users/", request_body.to_json, headers

      response_body = JSON.parse(last_response.body)
      created_user = User.find_by(login: "jdoe")
      expect(response_body).to eq("active" => true,
                                  "emails" => [{ "primary" => true,
                                                 "type" => "work",
                                                 "value" => "jdoe@example.com" }],
                                  "externalId" => external_user_id,
                                  "groups" => [],
                                  "id" => created_user.id.to_s,
                                  "meta" => { "created" => created_user.created_at.iso8601,
                                              "lastModified" => created_user.updated_at.iso8601,
                                              "location" => "http://test.host/scim_v2/Users/#{created_user.id}",
                                              "resourceType" => "User" },
                                  "name" => { "familyName" => "Doe",
                                              "givenName" => "John" },
                                  "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                  "userName" => "jdoe")
    end
  end

  describe "DELETE /scim_v2/Users/:id" do
    context "when users_deletable_by_admins is enabled", with_settings: { users_deletable_by_admins: true } do
      it do
        group

        delete "/scim_v2/Users/#{user.id}", "", headers

        expect(last_response.body).to eq("")
        expect(last_response).to have_http_status(204)

        get "/scim_v2/Users/#{user.id}", "", headers

        expect(last_response).to have_http_status(404)
        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          "detail" => "Resource \"#{user.id}\" not found",
          "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
          "status" => "404"
        )

        perform_enqueued_jobs
        assert_performed_jobs 1

        get "/scim_v2/Users/#{user.id}", "", headers

        expect(last_response).to have_http_status(404)
        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq(
          "detail" => "Resource \"#{user.id}\" not found",
          "schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
          "status" => "404"
        )
      end
    end

    context "when users_deletable_by_admins is disabled", with_settings: { users_deletable_by_admins: false } do
      it "responds with 403 error" do
        group
        delete "/scim_v2/Users/#{user.id}", "", headers

        response_body = JSON.parse(last_response.body)
        expect(response_body).to eq("schemas" => ["urn:ietf:params:scim:api:messages:2.0:Error"],
                                    "detail" => "Action forbidden: insufficient permissions.",
                                    "status" => "403")
        expect(last_response).to have_http_status(403)
      end
    end
  end

  describe "PUT /scim_v2/Users/:id" do
    before { group }

    let(:new_external_user_id) { "new_idp_user_id_123asdqwe12345" }

    it "updates existing user by replacing with newly provided data" do
      request_body = {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "externalId" => new_external_user_id,
        "userName" => "jdoe",
        "name" => {
          "givenName" => "John",
          "familyName" => "Doe"
        },
        "active" => true,
        "emails" => [
          {
            "value" => "jdoe@example.com",
            "type" => "work",
            "primary" => true
          }
        ]
      }

      put "/scim_v2/Users/#{user.id}", request_body.to_json, headers

      response_body = JSON.parse(last_response.body)
      user.reload
      expect(response_body).to eq("active" => true,
                                  "emails" => [{ "primary" => true,
                                                 "type" => "work",
                                                 "value" => request_body["emails"].first["value"] }],
                                  "externalId" => new_external_user_id,
                                  "groups" => [{ "value" => group.id.to_s }],
                                  "id" => user.id.to_s,
                                  "meta" => { "created" => user.created_at.iso8601,
                                              "lastModified" => user.updated_at.iso8601,
                                              "location" => "http://test.host/scim_v2/Users/#{user.id}",
                                              "resourceType" => "User" },
                                  "name" => { "familyName" => request_body["name"]["familyName"],
                                              "givenName" => request_body["name"]["givenName"] },
                                  "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                  "userName" => request_body["userName"])
    end
  end

  describe "PATCH /scim_v2/Users/:id" do
    let(:new_external_user_id) { "new_idp_user_id_123asdqwe12345" }

    before { group }

    it "changes external_id" do
      request_body = {
        "schemas" =>
        ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        "Operations" => [{
          "op" => "replace",
          "path" => "externalId",
          "value" => new_external_user_id
        }]
      }
      patch "/scim_v2/Users/#{user.id}", request_body.to_json, headers

      response_body = JSON.parse(last_response.body)
      user.reload
      expect(response_body).to eq("active" => true,
                                  "emails" => [{ "primary" => true,
                                                 "type" => "work",
                                                 "value" => user.mail }],
                                  "externalId" => new_external_user_id,
                                  "groups" => [{ "value" => group.id.to_s }],
                                  "id" => user.id.to_s,
                                  "meta" => { "created" => user.created_at.iso8601,
                                              "lastModified" => user.updated_at.iso8601,
                                              "location" => "http://test.host/scim_v2/Users/#{user.id}",
                                              "resourceType" => "User" },
                                  "name" => { "familyName" => user.lastname,
                                              "givenName" => user.firstname },
                                  "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                  "userName" => user.login)
    end

    it "changes email value" do
      new_email_value = "qwertty@gmail.com"
      request_body =    {
        "schemas" =>
        ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        "Operations" => [{
          "op" => "replace",
          "path" => "emails[type eq \"work\"]",
          "value" =>
                            {
                              "type" => "work",
                              "value" => new_email_value,
                              "primary" => true
                            }
        }]
      }
      patch "/scim_v2/Users/#{user.id}", request_body.to_json, headers

      response_body = JSON.parse(last_response.body)
      user.reload
      expect(response_body).to eq("active" => true,
                                  "emails" => [{ "primary" => true,
                                                 "type" => "work",
                                                 "value" => new_email_value }],
                                  "externalId" => user.scim_external_id,
                                  "groups" => [{ "value" => group.id.to_s }],
                                  "id" => user.id.to_s,
                                  "meta" => { "created" => user.created_at.iso8601,
                                              "lastModified" => user.updated_at.iso8601,
                                              "location" => "http://test.host/scim_v2/Users/#{user.id}",
                                              "resourceType" => "User" },
                                  "name" => { "familyName" => user.lastname,
                                              "givenName" => user.firstname },
                                  "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
                                  "userName" => user.login)
    end
  end
end
