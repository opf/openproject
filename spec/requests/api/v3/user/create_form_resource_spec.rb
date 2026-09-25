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

RSpec.describe API::V3::Users::CreateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:path) { api_v3_paths.create_user_form }
  let(:body) { response.body }
  let(:base_payload) do
    {
      email: "cfuser@example.com",
      status: "invited"
    }
  end

  before do
    login_as(current_user)

    post path, payload.to_json
  end

  subject(:response) { last_response }

  context "with authorized user" do
    shared_let(:current_user) { create(:user, global_permissions: [:create_user]) }

    describe "empty params" do
      let(:payload) do
        {}
      end

      # rubocop:disable RSpec/ExampleLength
      it "returns a payload with validation errors",
         :aggregate_failures,
         with_settings: { default_language: :es } do
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_json_eql("Form".to_json).at_path("_type")

        expect(body)
          .to be_json_eql("".to_json)
                .at_path("_embedded/payload/login")
        expect(body)
          .to be_json_eql("".to_json)
                .at_path("_embedded/payload/email")
        expect(body)
          .to be_json_eql("es".to_json)
                .at_path("_embedded/payload/language")
        expect(body)
          .to be_json_eql("active".to_json)
                .at_path("_embedded/payload/status")

        expect(body)
          .to have_json_size(5)
                .at_path("_embedded/validationErrors")

        expect(body)
          .to have_json_path("_embedded/validationErrors/password")
        expect(body)
          .to have_json_path("_embedded/validationErrors/login")
        expect(body)
          .to have_json_path("_embedded/validationErrors/email")
        expect(body)
          .to have_json_path("_embedded/validationErrors/firstName")
        expect(body)
          .to have_json_path("_embedded/validationErrors/lastName")

        expect(body)
          .not_to have_json_path("_links/commit")
      end
      # rubocop:enable RSpec/ExampleLength
    end

    describe "inviting a user" do
      let(:payload) { base_payload }

      it "returns a valid payload", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_json_eql("Form".to_json).at_path("_type")

        expect(body)
          .to be_json_eql("invited".to_json)
                .at_path("_embedded/payload/status")

        expect(body)
          .to be_json_eql("cfuser@example.com".to_json)
                .at_path("_embedded/payload/email")

        expect(body)
          .to be_json_eql("cfuser".to_json)
                .at_path("_embedded/payload/firstName")

        expect(body)
          .to be_json_eql("@example.com".to_json)
                .at_path("_embedded/payload/lastName")

        expect(body)
          .to have_json_size(0)
                .at_path("_embedded/validationErrors")
      end
    end

    describe "with custom fields" do
      let!(:custom_field) do
        create(:user_custom_field, :string)
      end
      let!(:list_custom_field) do
        create(:user_custom_field, :list)
      end
      let(:list_item_href) { api_v3_paths.custom_field_item(list_custom_field.possible_values.first.id) }

      let(:payload) do
        {
          **base_payload,
          custom_field.attribute_name(:camel_case) => "A custom value",
          _links: {
            list_custom_field.attribute_name(:camel_case) => {
              href: list_item_href
            }
          }
        }
      end

      it "returns a valid form response" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_json_eql("Form".to_json).at_path("_type")

        expect(body)
          .to be_json_eql("invited".to_json)
                .at_path("_embedded/payload/status")

        expect(body)
          .to be_json_eql("cfuser@example.com".to_json)
                .at_path("_embedded/payload/email")

        expect(body)
          .to be_json_eql("cfuser".to_json)
                .at_path("_embedded/payload/firstName")

        expect(body)
          .to be_json_eql("@example.com".to_json)
                .at_path("_embedded/payload/lastName")

        expect(body)
          .to be_json_eql("A custom value".to_json)
                .at_path("_embedded/payload/customField#{custom_field.id}")

        expect(body)
          .to be_json_eql(list_item_href.to_json)
                .at_path("_embedded/payload/_links/customField#{list_custom_field.id}/href")

        expect(body)
          .to have_json_size(0)
                .at_path("_embedded/validationErrors")
      end
    end

    context "with a required custom field" do
      shared_let(:required_custom_field) do
        create(:user_custom_field,
               :text,
               name: "Department",
               is_required: true)
      end

      context "when no custom field value is provided" do
        let(:payload) { base_payload }

        it "has validation errors for the required custom field", :aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(body)
            .to have_json_size(0)
                  .at_path("_embedded/validationErrors")
        end
      end

      context "when the custom field is provided but empty" do
        let(:payload) do
          {
            **base_payload,
            required_custom_field.attribute_name(:camel_case) => {
              raw: ""
            }
          }
        end

        it "has validation errors for the required custom field", :aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(body)
            .to have_json_size(0)
                  .at_path("_embedded/validationErrors")
        end
      end

      context "when the custom field value is provided and valid" do
        let(:payload) do
          {
            **base_payload,
            required_custom_field.attribute_name(:camel_case) => {
              raw: "Engineering"
            }
          }
        end

        it "has no validation errors", :aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(body).to have_json_size(0).at_path("_embedded/validationErrors")
          expect(body)
            .to be_json_eql("Engineering".to_json)
            .at_path("_embedded/payload/customField#{required_custom_field.id}/raw")
          expect(body)
            .to be_json_eql(api_v3_paths.users.to_json)
            .at_path("_links/commit/href")
        end
      end
    end

    context "with a visible custom field" do
      let(:visible_custom_field) do
        create(:user_custom_field, :text)
      end

      let(:payload) do
        {
          **base_payload,
          visible_custom_field.attribute_name(:camel_case) => {
            raw: "CF text"
          }
        }
      end

      it "has no validation errors" do
        expect(response).to have_http_status(:ok)
        expect(body).to have_json_size(0).at_path("_embedded/validationErrors")
        expect(body)
          .to be_json_eql("CF text".to_json)
          .at_path("_embedded/payload/customField#{visible_custom_field.id}/raw")
        expect(body)
          .to be_json_eql(api_v3_paths.users.to_json)
          .at_path("_links/commit/href")
      end
    end

    context "with an admin only custom field" do
      let(:is_required) { false }
      let!(:admin_only_custom_field) do
        create(:user_custom_field, :text, admin_only: true, is_required:)
      end

      let(:payload) do
        {
          **base_payload,
          admin_only_custom_field.attribute_name(:camel_case) => {
            raw: "CF text"
          }
        }
      end

      context "with admin permissions" do
        let(:current_user) { create(:admin) }

        it "has no validation errors", :aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(body).to have_json_size(0).at_path("_embedded/validationErrors")
          expect(body)
            .to be_json_eql("CF text".to_json)
            .at_path("_embedded/payload/customField#{admin_only_custom_field.id}/raw")
          expect(body)
            .to be_json_eql(api_v3_paths.users.to_json)
            .at_path("_links/commit/href")
        end
      end

      context "with non-admin permissions" do
        it "ignores the invisible custom field", :aggregate_failures do
          expect(response).to have_http_status(:ok)
          expect(body)
            .not_to have_json_path("_embedded/payload/customField#{admin_only_custom_field.id}/raw")
          expect(body).to have_json_size(0).at_path("_embedded/validationErrors")
          expect(body)
            .to be_json_eql(api_v3_paths.users.to_json)
            .at_path("_links/commit/href")
        end

        context "and when the custom field is required" do
          let(:is_required) { true }
          let(:payload) { base_payload }

          it "ignores the invisible custom field", :aggregate_failures do
            expect(response).to have_http_status(:ok)
            expect(body)
              .not_to have_json_path("_embedded/payload/customField#{admin_only_custom_field.id}/raw")
            expect(body).to have_json_size(0).at_path("_embedded/validationErrors")
            expect(body)
              .to be_json_eql(api_v3_paths.users.to_json)
              .at_path("_links/commit/href")
          end
        end
      end
    end
  end

  context "with unauthorized user" do
    shared_let(:current_user) { create(:user) }
    let(:payload) do
      {}
    end

    it_behaves_like "unauthorized access"
  end
end
