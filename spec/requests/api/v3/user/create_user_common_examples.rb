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

RSpec.shared_examples "represents the created user" do |expected_attributes|
  it "returns the represented user" do
    send_request

    expect(last_response).to have_http_status(:created)
    expect(last_response.body).to have_json_type(Object).at_path("_links")
    expect(last_response.body)
      .to be_json_eql("User".to_json)
            .at_path("_type")

    parameters.merge!(expected_attributes) if expected_attributes

    user = User.find_by!(login: parameters.fetch(:login, parameters[:email]))
    expect(user.firstname).to eq(parameters[:firstName])
    expect(user.lastname).to eq(parameters[:lastName])
    expect(user.mail).to eq(parameters[:email])
  end
end

RSpec.shared_examples "property is not writable" do |attribute_name|
  it "returns an error for the unwritable property" do
    send_request

    attr = JSON.parse(last_response.body).dig "_embedded", "details", "attribute"

    expect(last_response).to have_http_status :unprocessable_entity
    expect(attr).to eq attribute_name
  end
end

RSpec.shared_examples "create user request flow" do
  let(:errors) { parse_json(last_response.body)["_embedded"]["errors"] }

  describe "empty request body" do
    let(:parameters) { {} }

    it "returns an erroneous response" do
      send_request

      expect(last_response).to have_http_status(:unprocessable_entity)

      expect(errors.count).to eq(5)
      expect(errors.collect { |el| el["_embedded"]["details"]["attribute"] })
        .to contain_exactly("password", "login", "firstName", "lastName", "email")

      expect(last_response.body)
        .to be_json_eql("urn:openproject-org:api:v3:errors:MultipleErrors".to_json)
              .at_path("errorIdentifier")
    end
  end

  describe "invited status" do
    let(:status) { "invited" }
    let(:invitation_request) do
      {
        status:,
        email: "foo@example.org"
      }
    end

    describe "invitation successful" do
      before do
        expect(OpenProject::Notifications).to receive(:send) do |event, _|
          expect(event).to eq "user_invited"
        end
      end

      context "only mail set" do
        let(:parameters) { invitation_request }

        it_behaves_like "represents the created user",
                        firstName: "foo",
                        lastName: "@example.org"

        it "sets the other attributes" do
          send_request

          user = User.find_by!(login: "foo@example.org")
          expect(user.firstname).to eq("foo")
          expect(user.lastname).to eq("@example.org")
          expect(user.mail).to eq("foo@example.org")
        end
      end

      context "mail and name set" do
        let(:parameters) { invitation_request.merge(firstName: "First", lastName: "Last") }

        it_behaves_like "represents the created user"
      end
    end

    context "missing email" do
      let(:parameters) { { status: } }

      it "marks the mail as missing" do
        send_request

        expect(last_response.body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:MultipleErrors".to_json)
                .at_path("errorIdentifier")

        expect(errors.count).to eq 4

        attributes = errors.map { |error| error.dig("_embedded", "details", "attribute") }
        expect(attributes).to contain_exactly("login", "firstName", "lastName", "email")
      end
    end
  end

  describe "invalid status" do
    let(:parameters) { { status: "blablu" } }

    it "returns an erroneous response" do
      send_request

      expect(last_response).to have_http_status(:unprocessable_entity)

      expect(errors).not_to be_empty
      expect(last_response.body)
        .to be_json_eql("urn:openproject-org:api:v3:errors:MultipleErrors".to_json)
              .at_path("errorIdentifier")

      expect(errors.collect { |el| el["message"] })
        .to include "Status is not a valid status for new users."
    end
  end
end
