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

RSpec.shared_context "create placeholder user request context" do
  include API::V3::Utilities::PathHelper

  let(:parameters) do
    { name: "PLACEHOLDER" }
  end

  let(:send_request) do
    header "Content-Type", "application/json"
    post api_v3_paths.placeholder_users, parameters.to_json
  end

  let(:parsed_response) { JSON.parse(last_response.body) }
end

RSpec.shared_examples "create placeholder user request flow" do
  include_context "create placeholder user request context"

  describe "with EE", with_ee: %i[placeholder_users] do
    describe "empty request body" do
      let(:parameters) { {} }

      it "returns an erroneous response" do
        send_request

        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(last_response.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyConstraintViolation".to_json)
                .at_path("errorIdentifier")

        expect(parsed_response["_embedded"]["details"]["attribute"])
          .to eq "name"
      end
    end

    it "creates the placeholder when valid" do
      send_request

      expect(last_response).to have_http_status(:created)
      placeholder = PlaceholderUser.find_by(name: parameters[:name])
      expect(placeholder).to be_present
    end

    describe "when the user name already exists" do
      let!(:placeholder) { create(:placeholder_user, name: "PLACEHOLDER") }

      it "returns an error" do
        send_request

        expect(last_response).to have_http_status(:unprocessable_entity)
        expect(last_response.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyConstraintViolation".to_json)
                .at_path("errorIdentifier")

        expect(parsed_response["_embedded"]["details"]["attribute"])
          .to eq "name"

        expect(parsed_response["message"])
          .to eq "Name has already been taken."
      end
    end
  end

  describe "without ee" do
    it "adds an error that its only available in EE" do
      send_request

      expect(last_response).to have_http_status(:unprocessable_entity)
      expect(parsed_response["message"])
        .to eq("Placeholder Users is only available in the OpenProject Enterprise edition")

      expect(last_response.body)
        .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyConstraintViolation".to_json)
              .at_path("errorIdentifier")
    end
  end
end
