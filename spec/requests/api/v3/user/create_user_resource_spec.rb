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

require "spec_helper"
require "rack/test"
require_relative "create_user_common_examples"

RSpec.describe API::V3::Users::UsersAPI do
  include API::V3::Utilities::PathHelper

  let(:path) { api_v3_paths.users }
  let(:parameters) do
    {
      status: "active",
      login: "myusername",
      firstName: "Foo",
      lastName: "Bar",
      email: "foobar@example.org",
      language: "de"
    }
  end

  before do
    login_as(current_user)
  end

  def send_request
    header "Content-Type", "application/json"
    post path, parameters.to_json
  end

  describe "admin user" do
    let(:current_user) { create(:admin) }

    it_behaves_like "create user request flow"

    context "with auth_source" do
      let(:ldap_auth_source_id) { "some_ldap" }
      let(:auth_source) { create(:ldap_auth_source, name: ldap_auth_source_id) }

      context "ID" do
        before do
          parameters[:_links] = {
            auth_source: {
              href: "/api/v3/auth_sources/#{auth_source.id}"
            }
          }
        end

        it "creates the user with the given auth_source ID" do
          send_request

          user = User.find_by(login: parameters[:login])

          expect(user.ldap_auth_source).to eq auth_source
        end

        it_behaves_like "represents the created user"
      end

      context "name" do
        before do
          parameters[:_links] = {
            auth_source: {
              href: "/api/v3/auth_sources/#{auth_source.name}"
            }
          }
        end

        it "creates the user with the given auth_source ID" do
          send_request

          user = User.find_by(login: parameters[:login])

          expect(user.ldap_auth_source).to eq auth_source
        end

        it_behaves_like "represents the created user"
      end

      context "invalid identifier" do
        before do
          parameters[:_links] = {
            auth_source: {
              href: "/api/v3/auth_sources/foobar"
            }
          }
        end

        it "returns an error on that attribute" do
          send_request

          expect(last_response).to have_http_status(:unprocessable_entity)

          expect(last_response.body)
            .to be_json_eql("authSource".to_json)
                  .at_path("_embedded/details/attribute")

          expect(last_response.body)
            .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyConstraintViolation".to_json)
                  .at_path("errorIdentifier")
        end
      end
    end

    describe "active status" do
      let(:parameters) do
        {
          status: "active",
          login: "myusername",
          firstName: "Foo",
          lastName: "Bar",
          email: "foobar@example.org",
          language: "de"
        }
      end

      context "with identity_url" do
        let(:identity_url) { "google:3289272389298" }

        before do
          parameters[:identityUrl] = identity_url
        end

        it "creates the user with the given identity_url" do
          send_request

          user = User.find_by(login: parameters[:login])

          expect(user.identity_url).to eq identity_url
        end

        it_behaves_like "represents the created user"
      end

      context "with password" do
        let(:password) { "admin!admin!" }

        before do
          parameters[:password] = password
        end

        it "returns the represented user" do
          send_request

          expect(last_response.body).not_to have_json_path("_embedded/errors")
          expect(last_response.body).to have_json_type(Object).at_path("_links")
          expect(last_response.body)
            .to be_json_eql("User".to_json)
                  .at_path("_type")
        end

        it_behaves_like "represents the created user"

        context "empty password" do
          let(:password) { "" }

          it "marks the password missing and too short" do
            send_request

            errors = parse_json(last_response.body)["_embedded"]["errors"]
            expect(errors.count).to eq(2)
            expect(errors.collect { |el| el["_embedded"]["details"]["attribute"] })
              .to match_array %w(password password)
          end
        end
      end
    end
  end

  describe "user with global user create permission" do
    shared_let(:current_user) { create(:user, global_permissions: [:create_user]) }

    it_behaves_like "create user request flow"

    describe "active status" do
      context "with identity_url" do
        let(:identity_url) { "google:3289272389298" }

        before do
          parameters[:identityUrl] = identity_url
        end

        it_behaves_like "property is not writable", "identityUrl"
      end

      context "with password" do
        let(:password) { "admin!admin!" }

        before do
          parameters[:password] = password
        end

        it_behaves_like "property is not writable", "password"
      end
    end

    context "with auth_source" do
      let(:ldap_auth_source_id) { "some_ldap" }
      let(:auth_source) { create(:ldap_auth_source, name: ldap_auth_source_id) }

      before do
        parameters[:_links] = {
          auth_source: {
            href: "/api/v3/auth_sources/#{auth_source.id}"
          }
        }
      end

      it "creates the user with the given auth source id" do
        send_request

        user = User.find_by(login: parameters[:login])

        expect(user.ldap_auth_source).to eq auth_source
      end
    end
  end

  describe "unauthorized user" do
    let(:current_user) { build(:user) }
    let(:parameters) { { status: "invited", email: "foo@example.org" } }

    it "returns an erroneous response" do
      send_request
      expect(last_response).to have_http_status(:forbidden)
    end
  end
end
