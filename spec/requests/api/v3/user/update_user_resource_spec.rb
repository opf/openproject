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
  let(:user) { create(:user) }
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
      let(:parameters) { { email: "foo@example.org", language: "de" } }

      it_behaves_like "successful update", mail: "foo@example.org", language: "de"
    end

    describe "attribute collision" do
      let(:parameters) { { email: "foo@example.org" } }
      let(:collision) { create(:user, mail: "foo@example.org") }

      before do
        collision
      end

      it "returns an erroneous response" do
        send_request

        expect(last_response).to have_http_status(:unprocessable_entity)

        expect(last_response.body)
          .to be_json_eql("email".to_json)
                .at_path("_embedded/details/attribute")

        expect(last_response.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyConstraintViolation".to_json)
                .at_path("errorIdentifier")
      end
    end
  end

  describe "admin user" do
    let(:current_user) { build(:admin) }

    it_behaves_like "update flow"

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

    describe "unknown user" do
      let(:parameters) { { email: "foo@example.org" } }
      let(:path) { api_v3_paths.user(666) }

      it "responds with 404" do
        send_request
        expect(last_response).to have_http_status(:not_found)
      end
    end
  end

  describe "user with global manage_user permission" do
    shared_let(:global_manage_user) { create(:user, global_permissions: :manage_user) }
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
  end

  describe "unauthorized user" do
    let(:current_user) { build(:user) }
    let(:parameters) { { email: "new@example.org" } }

    it "returns an erroneous response" do
      send_request
      expect(last_response).to have_http_status(:forbidden)
    end
  end
end
