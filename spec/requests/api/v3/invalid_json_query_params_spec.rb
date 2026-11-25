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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "API v3 collections with malformed JSON query parameters", content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project) }

  before { login_as admin }

  shared_examples "a malformed query parameter" do |path, query, parameter|
    it "responds with 400 for GET #{path}?#{query.to_query}", :aggregate_failures do
      get "#{path}?#{query.to_query}"

      expect(last_response).to have_http_status(:bad_request)
      expect(last_response.body)
        .to be_json_eql("urn:openproject-org:api:v3:errors:InvalidQuery".to_json)
        .at_path("errorIdentifier")
      expect(last_response.body)
        .to be_json_eql(I18n.t("api_v3.errors.missing_or_malformed_parameter", parameter:).to_json)
        .at_path("message")
    end
  end

  context "with invalid JSON" do
    it_behaves_like "a malformed query parameter", "/api/v3/days", { filters: "" }, "filters"
    it_behaves_like "a malformed query parameter", "/api/v3/views", { filters: ".exe" }, "filters"
    it_behaves_like "a malformed query parameter", "/api/v3/versions", { sortBy: "" }, "sortBy"
    it_behaves_like "a malformed query parameter", "/api/v3/time_entries", { sortBy: "Q" }, "sortBy"
    it_behaves_like "a malformed query parameter", "/api/v3/documents", { sortBy: "" }, "sortBy"
    it_behaves_like "a malformed query parameter", "/api/v3/work_packages/schemas", { filters: "" }, "filters"
  end

  context "with JSON of the wrong structure" do
    it_behaves_like "a malformed query parameter", "/api/v3/views", { filters: "[1]" }, "filters"
    it_behaves_like "a malformed query parameter", "/api/v3/views", { filters: '{"id":1}' }, "filters"
    it_behaves_like "a malformed query parameter", "/api/v3/views", { filters: '[{"id":1}]' }, "filters"
    it_behaves_like "a malformed query parameter", "/api/v3/views", { filters: "[{}]" }, "filters"
    it_behaves_like "a malformed query parameter", "/api/v3/time_entries", { sortBy: '[["id"]]' }, "sortBy"
    it_behaves_like "a malformed query parameter", "/api/v3/versions", { sortBy: '"name"' }, "sortBy"
    it_behaves_like "a malformed query parameter", "/api/v3/versions", { sortBy: "[1]" }, "sortBy"
  end

  context "with a valid structure" do
    it "still accepts sortBy as an object" do
      get "/api/v3/versions?#{{ sortBy: '{"name":"asc"}' }.to_query}"

      expect(last_response).to have_http_status(:ok)
    end
  end
end
