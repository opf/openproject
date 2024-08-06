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
#++

require "spec_helper"
require "rack/test"

RSpec.describe "API v3 CORS headers",
               content_type: :json do
  include Rack::Test::Methods
  include Capybara::RSpecMatchers
  include API::V3::Utilities::PathHelper

  shared_examples "outputs CORS headers" do |request_path|
    it "outputs CORS headers", :aggregate_failures do
      options request_path,
              nil,
              "HTTP_ORIGIN" => "https://foo.example.com",
              "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "GET",
              "HTTP_ACCESS_CONTROL_REQUEST_HEADERS" => "test"

      expect(last_response.headers["Access-Control-Allow-Origin"]).to eq("https://foo.example.com")
      expect(last_response.headers["Access-Control-Allow-Methods"]).to eq("GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS")
      expect(last_response.headers["Access-Control-Allow-Headers"]).to eq("test")
      expect(last_response.headers).to have_key("Access-Control-Max-Age")
    end

    it "rejects CORS headers for invalid origin" do
      options request_path,
              nil,
              "HTTP_ORIGIN" => "invalid.example.com",
              "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "GET",
              "HTTP_ACCESS_CONTROL_REQUEST_HEADERS" => "test"

      expect(last_response.headers).not_to have_key "Access-Control-Allow-Origin"
      expect(last_response.headers).not_to have_key "Access-Control-Allow-Methods"
      expect(last_response.headers).not_to have_key "Access-Control-Allow-Headers"
      expect(last_response.headers).not_to have_key "Access-Control-Max-Age"
    end
  end

  context "with setting enabled",
          with_settings: { apiv3_cors_enabled: true } do
    context "with allowed origin set to specific values",
            with_settings: { apiv3_cors_origins: %w[https://foo.example.com bla.test] } do
      it_behaves_like "outputs CORS headers", "/api/v3"
      it_behaves_like "outputs CORS headers", "/oauth/token"
      it_behaves_like "outputs CORS headers", "/oauth/authorize"
      it_behaves_like "outputs CORS headers", "/oauth/revoke"

      # CORS needs to output headers even if you're unauthorized to allow authentication
      # to happen
      it "returns the CORS header on an unauthorized resource as well", :aggregate_failures do
        options "/api/v3/work_packages/form",
                nil,
                "HTTP_ORIGIN" => "https://foo.example.com"

        expect(last_response.headers["Access-Control-Allow-Origin"]).to eq("https://foo.example.com")
        expect(last_response.headers["Access-Control-Allow-Methods"]).to eq("GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS")
        expect(last_response.headers).to have_key("Access-Control-Max-Age")
      end
    end
  end

  context "when disabled",
          with_settings: { apiv3_cors_enabled: false, apiv3_cors_origins: %w[foo.example.com] } do
    it "does not output CORS headers even though origin matches", :aggregate_failures do
      options "/api/v3",
              nil,
              "HTTP_ORIGIN" => "foo.example.com",
              "HTTP_ACCESS_CONTROL_REQUEST_METHOD" => "GET",
              "HTTP_ACCESS_CONTROL_REQUEST_HEADERS" => "test"

      expect(last_response.headers).not_to have_key "Access-Control-Allow-Origin"
      expect(last_response.headers).not_to have_key "Access-Control-Allow-Methods"
      expect(last_response.headers).not_to have_key "Access-Control-Allow-Headers"
      expect(last_response.headers).not_to have_key "Access-Control-Max-Age"
    end
  end
end
