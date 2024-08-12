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
      let(:payload) do
        {
          email: "foo@example.com",
          status: "invited"
        }
      end

      it "returns a valid payload", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_json_eql("Form".to_json).at_path("_type")

        expect(body)
          .to be_json_eql("invited".to_json)
                .at_path("_embedded/payload/status")

        expect(body)
          .to be_json_eql("foo@example.com".to_json)
                .at_path("_embedded/payload/email")

        expect(body)
          .to be_json_eql("foo".to_json)
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
      let(:custom_option_href) { api_v3_paths.custom_option(list_custom_field.custom_options.first.id) }

      let(:payload) do
        {
          email: "cfuser@example.com",
          status: "invited",
          custom_field.attribute_name(:camel_case) => "A custom value",
          _links: {
            list_custom_field.attribute_name(:camel_case) => {
              href: custom_option_href
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
          .to be_json_eql(custom_option_href.to_json)
                .at_path("_embedded/payload/_links/customField#{list_custom_field.id}/href")

        expect(body)
          .to have_json_size(0)
                .at_path("_embedded/validationErrors")
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
