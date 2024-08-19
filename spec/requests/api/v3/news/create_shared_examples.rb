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

RSpec.shared_context "create news request context" do
  include API::V3::Utilities::PathHelper

  let(:parameters) do
    {
      title: "My news entry",
      summary: "Hello from API",
      _links: {
        project: {
          href: api_v3_paths.project(project.id)
        }
      }
    }
  end

  let(:send_request) do
    header "Content-Type", "application/json"
    post api_v3_paths.newses, parameters.to_json
  end

  let(:parsed_response) { JSON.parse(last_response.body) }
end

RSpec.shared_examples "create news request flow" do
  include_context "create news request context"

  describe "empty request body" do
    let(:parameters) { {} }

    it "returns an erroneous response" do
      send_request

      expect(last_response.status).to eq(422)
      expect(last_response.body)
        .to be_json_eql("urn:openproject-org:api:v3:errors:MultipleErrors".to_json)
              .at_path("errorIdentifier")
    end
  end

  it "creates the news when valid" do
    send_request

    expect(last_response.status).to eq(201)
    news = News.find_by(title: parameters[:title])
    expect(news).to be_present
    expect(news.project).to eq(project)
    expect(news.author).to eq(user)
  end

  describe "when the title is missing" do
    it "returns an error" do
      header "Content-Type", "application/json"
      post api_v3_paths.newses, parameters.except(:title).to_json

      expect(last_response.status).to eq(422)
      expect(last_response.body)
        .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyConstraintViolation".to_json)
              .at_path("errorIdentifier")

      expect(parsed_response["_embedded"]["details"]["attribute"])
        .to eq "title"

      expect(parsed_response["message"])
        .to eq "Title can't be blank."
    end
  end
end
