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

RSpec.describe API::V3::Users::UpdateFormAPI, content_type: :json do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  shared_let(:text_custom_field) do
    create(:user_custom_field, :string)
  end
  shared_let(:list_custom_field) do
    create(:user_custom_field, :list)
  end
  shared_let(:user) do
    create(:user,
           text_custom_field.attribute_getter => "CF text",
           list_custom_field.attribute_getter => list_custom_field.custom_options.first)
  end

  let(:path) { api_v3_paths.user_form(user.id) }
  let(:body) { response.body }
  let(:payload) do
    {}
  end

  before do
    login_as(current_user)

    post path, payload.to_json
  end

  subject(:response) { last_response }

  context "with authorized user" do
    # Required to satisfy the Users::UpdateContract#at_least_one_admin_is_active
    shared_let(:default_admin) { create(:admin) }
    shared_let(:current_user) do
      create(:user, global_permissions: [:manage_user])
    end

    describe "empty payload" do
      it "returns a valid form", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_json_eql("Form".to_json).at_path("_type")

        expect(body)
          .to be_json_eql(user.mail.to_json)
                .at_path("_embedded/payload/email")

        expect(body)
          .to be_json_eql(user.firstname.to_json)
                .at_path("_embedded/payload/firstName")

        expect(body)
          .to be_json_eql(user.lastname.to_json)
                .at_path("_embedded/payload/lastName")

        expect(body)
          .to have_json_size(0)
                .at_path("_embedded/validationErrors")
      end
    end

    describe "with a writable status" do
      let(:payload) do
        {
          status: "locked"
        }
      end

      it "returns a valid response", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_json_eql("Form".to_json).at_path("_type")

        expect(subject.body)
          .to have_json_size(0)
                .at_path("_embedded/validationErrors")

        expect(body)
          .to be_json_eql("locked".to_json)
                .at_path("_embedded/payload/status")

        # Does not change the user's status
        user.reload
        expect(user.status).to eq "active"
      end
    end

    describe "with an empty firstname" do
      let(:payload) do
        {
          firstName: nil
        }
      end

      it "returns an invalid form", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to be_json_eql("Form".to_json).at_path("_type")

        expect(body)
          .to be_json_eql(user.mail.to_json)
                .at_path("_embedded/payload/email")

        expect(body)
          .not_to have_json_path("_embedded/payload/firstName")

        expect(body)
          .to be_json_eql(user.lastname.to_json)
                .at_path("_embedded/payload/lastName")

        expect(subject.body)
          .to have_json_size(1)
                .at_path("_embedded/validationErrors")

        expect(subject.body)
          .to have_json_path("_embedded/validationErrors/firstName")

        expect(subject.body)
          .not_to have_json_path("_links/commit")

        name_before = user.name

        expect(user.reload.name)
          .to eql name_before
      end
    end

    context "with a non existing id" do
      let(:path) { api_v3_paths.user_form(12345) }

      it "returns 404 Not found" do
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "with unauthorized user" do
    let(:current_user) { create(:user) }

    it_behaves_like "unauthorized access"
  end
end
