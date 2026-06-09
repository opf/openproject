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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe Wikis::Adapters::Providers::XWiki::Queries::ReferencingPages, :webmock do
  include XWikiStubs

  it "is registered" do
    expect(Wikis::Adapters::Registry.resolve("xwiki.queries.referencing_pages")).to eq(described_class)
  end

  describe "#call" do
    let(:user) { create(:user) }
    let(:wiki_provider) do
      create(:xwiki_provider, :with_connected_user, url: "https://xwiki.example.com/", connected_user: user)
    end
    let(:linkable) { create(:work_package) }
    let(:wikis_endpoint) { "https://xwiki.example.com/rest/wikis" }
    let(:auth_strategy) do
      Wikis::Adapters::Input::AuthStrategy.build(key: :bearer_token, user:, provider: wiki_provider).value!
    end
    let(:input_data) { Wikis::Adapters::Input::ReferencingPages.build(linkable:).value! }
    let(:query) { described_class.new(model: wiki_provider) }

    subject(:result) { query.call(input_data:, auth_strategy:) }

    context "when a single wiki returns results" do
      let(:page_identifier) { "xwiki:Main.Eric's Space.WebHome" }
      let(:page_rest_url) do
        "https://xwiki.example.com/rest/wikis/xwiki/spaces/Main/spaces/Eric%27s%20Space/pages/WebHome"
      end
      let(:page_absolute_url) { "https://xwiki.example.com/bin/view/Main/Eric%27s%20Space/" }

      before do
        stub_wiki_list(["xwiki"])
        stub_search("xwiki",
                    [{ "type" => "page",
                       "id" => page_identifier,
                       "title" => "Eric's Space #2",
                       "wiki" => "xwiki",
                       "space" => "Main.Eric's Space",
                       "pageName" => "WebHome",
                       "links" => [{ "href" => page_rest_url,
                                     "rel" => "http://www.xwiki.org/rel/page" }] }],
                    linkable:)
        stub_request(:get, page_rest_url)
          .with(headers: { "Authorization" => "Bearer user-bearer-token" })
          .to_return(
            status: 200,
            body: { "title" => "Eric's Space #2", "xwikiAbsoluteUrl" => page_absolute_url }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it { is_expected.to be_success }

      it "returns page infos resolved via page_info" do
        page_results = result.value!
        expect(page_results).to all(be_success)
        expect(page_results.map { it.value!.identifier }).to contain_exactly(page_identifier)
        expect(page_results.map { it.value!.title }).to contain_exactly("Eric's Space #2")
        expect(page_results.map { it.value!.href }).to contain_exactly(page_absolute_url)
      end
    end

    context "when a farm has multiple wikis with results" do
      let(:page_id_wiki1) { "xwiki:Main.WebHome" }
      let(:page_id_wiki2) { "myfarm:Docs.Index" }
      let(:page_rest_wiki1) { "https://xwiki.example.com/rest/wikis/xwiki/spaces/Main/pages/WebHome" }
      let(:page_rest_wiki2) { "https://xwiki.example.com/rest/wikis/myfarm/spaces/Docs/pages/Index" }

      before do
        stub_wiki_list(%w[xwiki myfarm])
        stub_search("xwiki", [{ "id" => page_id_wiki1, "title" => "Home",
                                "links" => [{ "href" => page_rest_wiki1, "rel" => "http://www.xwiki.org/rel/page" }] }],
                    linkable:)
        stub_search("myfarm", [{ "id" => page_id_wiki2, "title" => "Docs Index",
                                 "links" => [{ "href" => page_rest_wiki2, "rel" => "http://www.xwiki.org/rel/page" }] }],
                    linkable:)
        stub_request(:get, page_rest_wiki1)
          .with(headers: { "Authorization" => "Bearer user-bearer-token" })
          .to_return(status: 200,
                     body: { "title" => "Home", "xwikiAbsoluteUrl" => "https://xwiki.example.com/bin/view/Main/" }.to_json,
                     headers: { "Content-Type" => "application/json" })
        stub_request(:get, page_rest_wiki2)
          .with(headers: { "Authorization" => "Bearer user-bearer-token" })
          .to_return(status: 200,
                     body: { "title" => "Docs Index",
                             "xwikiAbsoluteUrl" => "https://xwiki.example.com/bin/view/Docs/" }.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it { is_expected.to be_success }

      it "aggregates results from all wikis" do
        page_results = result.value!
        expect(page_results).to all(be_success)
        expect(page_results.map { it.value!.identifier }).to contain_exactly(page_id_wiki1, page_id_wiki2)
      end
    end

    context "when the same page appears multiple times in results" do
      let(:page_identifier) { "xwiki:Main.WebHome" }
      let(:page_rest_url) { "https://xwiki.example.com/rest/wikis/xwiki/spaces/Main/pages/WebHome" }
      let(:page_absolute_url) { "https://xwiki.example.com/bin/view/Main/" }
      let(:duplicate_result) do
        { "id" => page_identifier, "title" => "Home",
          "links" => [{ "href" => page_rest_url, "rel" => "http://www.xwiki.org/rel/page" }] }
      end

      before do
        stub_wiki_list(["xwiki"])
        stub_search("xwiki", [duplicate_result, duplicate_result], linkable:)
        stub_request(:get, page_rest_url)
          .with(headers: { "Authorization" => "Bearer user-bearer-token" })
          .to_return(status: 200,
                     body: { "title" => "Home", "xwikiAbsoluteUrl" => page_absolute_url }.to_json,
                     headers: { "Content-Type" => "application/json" })
      end

      it { is_expected.to be_success }

      it "deduplicates by page identifier" do
        expect(result.value!.size).to eq(1)
        expect(result.value!.first.value!.identifier).to eq(page_identifier)
      end
    end

    context "when no pages are found across all wikis" do
      before do
        stub_wiki_list(["xwiki"])
        stub_search("xwiki", [], linkable:)
      end

      it { is_expected.to be_success }

      it "returns an empty list" do
        expect(result.value!).to eq([])
      end
    end

    context "when one wiki's search fails" do
      before do
        stub_wiki_list(%w[xwiki broken_wiki])
        stub_search("xwiki", [], linkable:)
        stub_request(:get, search_endpoint("broken_wiki", linkable)).to_return(status: 500, body: "Internal Server Error")
      end

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :request_failed)) }
    end

    context "when no OAuth token exists for the user" do
      let(:wiki_provider) { create(:xwiki_provider, :with_oauth_client, url: "https://xwiki.example.com/") }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :missing_token)) }
    end

    context "when the wikis preflight fails with unauthorized" do
      before { stub_request(:get, wikis_endpoint).to_return(status: 401, body: "") }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :unauthorized)) }
    end

    context "when the wikis preflight fails with a network error" do
      before { stub_request(:get, wikis_endpoint).to_timeout }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :connection_error)) }
    end
  end
end
