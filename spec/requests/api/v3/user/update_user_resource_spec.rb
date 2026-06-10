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

require "spec_helper"
require "rack/test"

RSpec.describe API::V3::Users::UsersAPI do
  include API::V3::Utilities::PathHelper

  let(:path) { api_v3_paths.user(user.id) }
  let!(:user) { create(:user) }
  let(:parameters) { {} }

  before do
    login_as(current_user)
  end

  def send_request
    header "Content-Type", "application/json"
    patch path, parameters.to_json
  end

  shared_examples "successful update" do |expected_attributes|
    it "responds with the represented updated user" do
      send_request

      expect(last_response).to have_http_status(:ok)
      expect(last_response.body).to have_json_type(Object).at_path("_links")
      expect(last_response.body)
        .to be_json_eql("User".to_json)
        .at_path("_type")

      updated_user = User.find(user.id)
      (expected_attributes || {}).each do |key, val|
        expect(updated_user.send(key)).to eq(val)
      end
    end
  end

  shared_examples "update flow" do
    describe "empty request body" do
      it_behaves_like "successful update"
    end

    describe "attribute change" do
      let(:parameters) { { login: "new.login", language: "de" } }

      it_behaves_like "successful update", login: "new.login", language: "de"
    end

    describe "attribute collision" do
      let(:parameters) { { login: "new.login" } }
      let(:collision) { create(:user, login: "new.login") }

      before do
        collision
      end

      it "returns an erroneous response" do
        send_request

        expect(last_response).to have_http_status(:unprocessable_entity)

        expect(last_response.body)
          .to be_json_eql("login".to_json)
                .at_path("_embedded/details/attribute")

        expect(last_response.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyConstraintViolation".to_json)
                .at_path("errorIdentifier")
      end
    end

    describe "updating name attribute" do
      let(:parameters) { { name: "Bobnelda Bobbit" } }

      it "responds with an error" do
        send_request

        expect(last_response).to have_http_status(:unprocessable_entity)

        expect(last_response.body)
          .to be_json_eql("name".to_json)
                .at_path("_embedded/details/attribute")

        expect(last_response.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyIsReadOnly".to_json)
                .at_path("errorIdentifier")
      end
    end

    describe "custom fields" do
      let!(:required_custom_field) do
        create(:user_custom_field,
               :text,
               name: "Department",
               is_required: true)
      end

      context "with a required custom field" do
        context "when no custom field value is provided" do
          let(:parameters) do
            {
              login: "new.login"
            }
          end

          it_behaves_like "successful update", login: "new.login"

          it "keeps the custom field value empty" do
            send_request
            expect(user.reload.typed_custom_value_for(required_custom_field))
              .to be_empty
          end
        end

        context "when the custom field is provided but empty" do
          let(:parameters) do
            {
              login: "new.login",
              required_custom_field.attribute_name(:camel_case) => {
                raw: ""
              }
            }
          end

          it "responds with 422 and explains the custom field error" do
            send_request
            expect(last_response).to have_http_status(:unprocessable_entity)

            response_body = parse_json(last_response.body)

            expect(response_body.dig("_embedded", "details", "attribute"))
              .to eq("customField#{required_custom_field.id}")
            expect(response_body["message"]).to eq("Department can't be blank.")
          end
        end

        context "when the custom field value is provided and valid" do
          let(:parameters) do
            {
              login: "new.login",
              required_custom_field.attribute_name(:camel_case) => {
                raw: "Engineering"
              }
            }
          end

          it_behaves_like "successful update", login: "new.login"

          it "updates the user with the custom field value" do
            send_request
            expect(user.reload.typed_custom_value_for(required_custom_field))
              .to eq("Engineering")
          end
        end
      end

      context "with a visible custom field" do
        let!(:custom_field) do
          create(:user_custom_field, :text)
        end

        let(:parameters) do
          {
            login: "new.login",
            custom_field.attribute_name(:camel_case) => {
              raw: "CF text"
            }
          }
        end

        it_behaves_like "successful update", login: "new.login"

        it "sets the cf value" do
          send_request
          expect(user.reload.typed_custom_value_for(custom_field))
            .to eq("CF text")
        end
      end

      context "with an admin only custom field" do
        let(:is_required) { false }
        let!(:admin_only_custom_field) do
          create(:user_custom_field, :text, admin_only: true, is_required:)
        end

        context "with admin permissions" do
          let(:current_user) { create(:admin) }
          let(:parameters) do
            {
              login: "new.login",
              admin_only_custom_field.attribute_name(:camel_case) => {
                raw: "CF text"
              }
            }
          end

          it_behaves_like "successful update", login: "new.login"

          it "sets the cf value" do
            send_request
            expect(user.reload.typed_custom_value_for(admin_only_custom_field))
              .to eq("CF text")
          end
        end

        context "with non-admin permissions" do
          let(:current_user) { create(:user, global_permissions: %i[manage_user view_all_principals]) }
          let(:parameters) do
            {
              login: "new.login",
              admin_only_custom_field.attribute_name(:camel_case) => {
                raw: "CF text"
              }
            }
          end

          it_behaves_like "successful update", login: "new.login"

          it "does not set the cf value" do
            send_request
            expect(user.reload.custom_values.where(custom_field: admin_only_custom_field))
              .to be_empty
          end

          context "and when the custom field is required" do
            let(:is_required) { true }
            let(:parameters) do
              {
                login: "new.login"
              }
            end

            it_behaves_like "successful update", login: "new.login"

            it "does not set the cf value" do
              send_request
              expect(user.reload.custom_values.where(custom_field: admin_only_custom_field))
                .to be_empty
            end
          end
        end
      end
    end
  end

  describe "admin user" do
    let(:current_user) { build(:admin) }

    it_behaves_like "update flow"

    describe "activation when the user limit is reached" do
      let(:parameters) { { status: "active" } }

      before do
        user.locked!
        allow(OpenProject::Enterprise).to receive(:user_limit_reached?).and_return(true)
      end

      it "returns an error and does not activate the user" do
        send_request

        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(user.reload).to be_locked
      end
    end

    describe "password update" do
      let(:password) { "my!new!password123" }
      let(:parameters) { { password: } }

      it "updates the users password correctly" do
        send_request
        expect(last_response).to have_http_status(:ok)

        updated_user = User.find(user.id)
        matches = updated_user.check_password?(password)
        expect(matches).to be(true)
      end
    end

    describe "email update" do
      let(:email) { "this.is.a.new@email.address" }
      let(:parameters) { { email:  email } }

      it "updates the users email correctly" do
        send_request
        expect(last_response).to have_http_status(:ok)

        updated_user = User.find(user.id)
        expect(updated_user.mail).to eq(email)
      end
    end

    describe "unknown user" do
      let(:parameters) { { login: "new.login" } }
      let(:path) { api_v3_paths.user(666) }

      it "responds with 404" do
        send_request
        expect(last_response).to have_http_status(:not_found)
      end
    end
  end

  describe "user with global manage_user permission" do
    shared_let(:global_manage_user) { create(:user, global_permissions: %i[manage_user view_all_principals]) }
    let(:current_user) { global_manage_user }

    it_behaves_like "update flow"

    describe "password update" do
      let(:password) { "my!new!password123" }
      let(:parameters) { { password: } }

      it "rejects the users password update" do
        send_request
        expect(last_response).to have_http_status(:unprocessable_entity)

        expect(last_response.body)
          .to be_json_eql("password".to_json)
                .at_path("_embedded/details/attribute")

        expect(last_response.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyIsReadOnly".to_json)
                .at_path("errorIdentifier")
      end
    end

    describe "email update" do
      let(:email) { "this.is.a.new@email.address" }
      let(:parameters) { { email: email } }

      it "rejects the users email update" do
        send_request
        expect(last_response).to have_http_status(:unprocessable_entity)

        expect(last_response.body)
          .to be_json_eql("email".to_json)
                .at_path("_embedded/details/attribute")

        expect(last_response.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyIsReadOnly".to_json)
                .at_path("errorIdentifier")
      end
    end
  end

  describe "unauthorized user" do
    let(:current_user) { build(:user) }
    let(:parameters) { { email: "new@example.org" } }

    it "returns an erroneous response" do
      send_request
      expect(last_response).to have_http_status(:not_found)
    end
  end

  describe "self update via /users/me" do
    let(:current_user) { create(:user) }
    let!(:user) { current_user }
    let(:path) { api_v3_paths.user("me") }

    describe "password update without current password" do
      let(:parameters) { { password: "my!new!password123" } }

      it "rejects the update and keeps the old password" do
        send_request

        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(current_user.reload.check_password?("adminADMIN!")).to be(true)
        expect(current_user.check_password?("my!new!password123")).to be(false)
      end
    end

    describe "password update with wrong current password" do
      let(:parameters) do
        {
          password: "my!new!password123",
          currentPassword: "wrong-password"
        }
      end

      it "rejects the update and keeps the old password" do
        send_request

        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(current_user.reload.check_password?("adminADMIN!")).to be(true)
        expect(current_user.check_password?("my!new!password123")).to be(false)
      end
    end

    describe "password update with valid current password" do
      let(:parameters) do
        {
          password: "my!new!password123",
          currentPassword: "adminADMIN!"
        }
      end

      it "updates the users password correctly" do
        send_request
        expect(last_response).to have_http_status(:ok)

        updated_user = User.find(current_user.id)
        expect(updated_user.check_password?("my!new!password123")).to be(true)
      end
    end
  end
end
