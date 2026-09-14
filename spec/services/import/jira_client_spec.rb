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
#++

require "spec_helper"

RSpec.describe Import::JiraClient do
  subject(:client) { described_class.new(url:, personal_access_token:) }

  let(:url) { "https://jira.example.com" }
  let(:personal_access_token) { "test-token" }

  describe "#initialize" do
    context "when personal_access_token is nil" do
      let(:personal_access_token) { nil }

      it "raises ApiError" do
        expect { client }.to raise_error(Import::JiraClient::ApiError)
      end
    end
  end

  describe "#custom_field_options", :webmock do
    include_context "with ssrf stubs"

    let(:options_url) { "#{url}/rest/api/2/customFields/10264/options" }

    def stub_options(query:, options:, total: :unset, status: 200)
      body = { options: }
      body[:total] = total == :unset ? options.size : total
      body.delete(:total) if total.nil?
      stub_request(:get, options_url)
        .with(query:)
        .to_return(status:, body: body.to_json, headers: { "Content-Type" => "application/json" })
    end

    def option(id, value)
      { "value" => value, "id" => id, "disabled" => false, "childrenIds" => [] }
    end

    it "returns the options of the field context the projects and issue types resolve to" do
      stub_options(query: { "projectIds" => "10012", "issueTypeIds" => "10100" }, options: [option(10200, "Red")])

      expect(client.custom_field_options(10264, project_ids: ["10012"], issue_type_ids: ["10100"]))
        .to eq([option(10200, "Red")])
    end

    it "joins several projects and issue types into one request" do
      request = stub_options(query: { "projectIds" => "10012,10013", "issueTypeIds" => "10100,10200" },
                             options: [option(10200, "Red")])

      client.custom_field_options(10264, project_ids: %w[10012 10013], issue_type_ids: %w[10100 10200])

      expect(request).to have_been_requested
    end

    it "asks without any parameter when no project or issue type is given" do
      request = stub_options(query: {}, options: [option(10200, "Red")])

      client.custom_field_options(10264)

      expect(request).to have_been_requested
    end

    it "reads a context whose options the first response already holds with a single request" do
      request = stub_options(query: {}, options: [option(10200, "Red")], total: 1)

      expect(client.custom_field_options(10264).size).to eq(1)
      expect(request).to have_been_requested.once
    end

    it "returns nothing for a context without options" do
      request = stub_options(query: {}, options: [], total: 0)

      expect(client.custom_field_options(10264)).to eq([])
      expect(request).to have_been_requested.once
    end

    it "reads on when the first response was short of the total" do
      stub_options(query: {}, options: [option(10200, "Red")], total: 3)
      stub_options(query: { "maxResults" => "10000", "page" => "1" },
                   options: [option(10200, "Red"), option(10201, "Purple"), option(10202, "Green")], total: 3)

      expect(client.custom_field_options(10264).pluck("value")).to eq(%w[Red Purple Green])
    end

    # Jira caps maxResults server side, so a page can come back smaller than the one asked for.
    it "keeps reading pages until the context holds as many options as the total promises" do
      stub_options(query: {}, options: [option(10200, "Red")], total: 4)
      stub_options(query: { "maxResults" => "10000", "page" => "1" },
                   options: [option(10200, "Red"), option(10201, "Purple")], total: 4)
      stub_options(query: { "maxResults" => "10000", "page" => "2" },
                   options: [option(10202, "Green"), option(10203, "Blue")], total: 4)

      expect(client.custom_field_options(10264).pluck("value")).to eq(%w[Red Purple Green Blue])
    end

    it "stops once a page adds no option the previous ones did not already hold" do
      stub_options(query: {}, options: [option(10200, "Red")], total: 4)
      stub_options(query: { "maxResults" => "10000", "page" => "1" }, options: [option(10200, "Red")], total: 4)
      second_page = stub_options(query: { "maxResults" => "10000", "page" => "2" },
                                 options: [option(10201, "Purple")], total: 4)

      expect(client.custom_field_options(10264).pluck("value")).to eq(%w[Red])
      expect(second_page).not_to have_been_requested
    end

    # An endpoint answering every page with the same options would otherwise never let go.
    it "gives up after the page limit when every page keeps adding options" do
      stub_options(query: {}, options: [option(10200, "Red")], total: nil)
      stub_request(:get, options_url)
        .with(query: hash_including({ "page" => /\d+/ }))
        .to_return do |request|
          page = CGI.parse(URI(request.uri).query).fetch("page").first.to_i
          { status: 200,
            body: { options: [option(10_200 + page, "Colour #{page}")] }.to_json,
            headers: { "Content-Type" => "application/json" } }
        end

      expect(client.custom_field_options(10264).size)
        .to eq(described_class::CUSTOM_FIELD_OPTIONS_PAGE_LIMIT + 1)
    end

    context "when Jira reports no total" do
      it "reads page by page until a page comes back empty" do
        stub_options(query: {}, options: [option(10200, "Red")], total: nil)
        stub_options(query: { "maxResults" => "10000", "page" => "1" },
                     options: [option(10200, "Red"), option(10201, "Purple")], total: nil)
        stub_options(query: { "maxResults" => "10000", "page" => "2" }, options: [option(10202, "Green")], total: nil)
        stub_options(query: { "maxResults" => "10000", "page" => "3" }, options: [], total: nil)

        expect(client.custom_field_options(10264).pluck("value")).to eq(%w[Red Purple Green])
      end

      it "returns nothing when the first page is already empty" do
        stub_options(query: {}, options: [], total: nil)
        stub_options(query: { "maxResults" => "10000", "page" => "1" }, options: [], total: nil)

        expect(client.custom_field_options(10264)).to eq([])
      end
    end

    # The endpoint only exists from Jira DC 9.3 on, and answers the same way for a field the token
    # cannot see; callers fall back to editmeta in both cases.
    it "raises UnsupportedEndpointError when the endpoint does not exist" do
      stub_request(:get, options_url).with(query: hash_including({})).to_return(status: 404)

      expect { client.custom_field_options(10264) }
        .to raise_error(Import::JiraClient::UnsupportedEndpointError, /customFields\/10264\/options/)
    end

    it "raises ApiError for any other error status" do
      stub_request(:get, options_url).with(query: hash_including({})).to_return(status: 500)

      expect { client.custom_field_options(10264) }.to raise_error(Import::JiraClient::ApiError)
    end
  end

  describe "SSRF protection" do
    context "when using a loopback address" do
      let(:url) { "http://127.0.0.1" }

      it "raises ConnectionError for API requests" do
        expect { client.server_info }
          .to raise_error(Import::JiraClient::ConnectionError)
      end

      it "raises ConnectionError for download_attachment" do
        expect { client.download_attachment("#{url}/attachment/123", "filename") }
          .to raise_error(Import::JiraClient::ConnectionError)
      end
    end

    context "when using a private network address (10.x.x.x)" do
      let(:url) { "http://10.0.0.1" }

      it "raises ConnectionError for API requests" do
        expect { client.projects }
          .to raise_error(Import::JiraClient::ConnectionError)
      end

      it "raises ConnectionError for download_attachment" do
        expect { client.download_attachment("#{url}/attachment/123", "filename") }
          .to raise_error(Import::JiraClient::ConnectionError)
      end
    end
  end
end
