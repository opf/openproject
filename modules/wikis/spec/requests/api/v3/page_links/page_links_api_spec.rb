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

RSpec.describe "API v3 wiki page links resource", content_type: :json do
  include API::V3::Utilities::PathHelper

  shared_let(:work_package) { create(:work_package) }
  shared_let(:internal_wiki) { create(:internal_wiki_provider) }
  shared_let(:xwiki_provider) { create(:xwiki_provider) }

  shared_let(:project) { work_package.project }

  shared_let(:user) { create(:user, member_with_permissions: { project => %i(view_work_packages manage_wiki_page_links) }) }

  shared_let(:relation_page_links) { create_list(:relation_wiki_page_link, 3, provider: xwiki_provider, linkable: work_package) }
  shared_let(:inline_page_links) { create_list(:inline_wiki_page_link, 3, provider: internal_wiki, linkable: work_package) }

  shared_let(:unrelated_page_links) do
    create_list(:inline_wiki_page_link, 3, provider: internal_wiki, linkable: create(:work_package, project: project))
  end

  before do
    login_as user
    stub_provider_queries
    unrelated_page_links
  end

  describe "GET /api/v3/work_packages/:id/wiki_page_links" do
    let(:path) { api_v3_paths.work_package_page_links(work_package.id) }

    context "with all preconditions met (happy path)" do
      before { get path }

      it_behaves_like "API V3 collection response", 6, 6, "WikiPageLink", "WikiPageLinkCollection" do
        let(:elements) { Wikis::PageLink.where(linkable: work_package).order(id: :desc).all }
      end
    end

    context "when filtered by provider" do
      let(:filter) { [{ provider: { operator: "=", values: [internal_wiki.universal_identifier] } }] }

      before do
        get "#{path}?filters=#{CGI.escape(filter.to_json)}"
      end

      it_behaves_like "API V3 collection response", 3, 3, "WikiPageLink", "WikiPageLinkCollection" do
        let(:elements) { Wikis::PageLink.where(linkable: work_package, provider: internal_wiki).order(id: :desc).all }
      end
    end
  end

  describe "GET /api/v3/wiki_page_links" do
    let(:unaccessible_links) { create_list(:relation_wiki_page_link, 2, provider: xwiki_provider) }
    let(:path) { api_v3_paths.wiki_page_links }

    context "with all preconditions met (happy path)" do
      before do
        unaccessible_links
        get path
      end

      it_behaves_like "API V3 collection response", 9, 9, "WikiPageLink", "WikiPageLinkCollection" do
        let(:elements) { Wikis::PageLink.where.not(id: unaccessible_links.pluck(:id)).order(id: :desc).all }
      end
    end

    context "when filtered by provider" do
      let(:filter) { [{ provider: { operator: "=", values: [internal_wiki.universal_identifier] } }] }

      before { get "#{path}?filters=#{CGI.escape(filter.to_json)}" }

      it_behaves_like "API V3 collection response", 6, 6, "WikiPageLink", "WikiPageLinkCollection" do
        let(:elements) { Wikis::PageLink.where(provider: internal_wiki).order(id: :desc).all }
      end
    end

    context "when filtered by link type" do
      let(:filter) do
        [{ wiki_page_link_type:
             { operator: "=", values: [API::V3::PageLinks::URN_PAGE_LINK_TYPE["Wikis::RelationPageLink"]] } }]
      end

      before { get "#{path}?filters=#{CGI.escape(filter.to_json)}" }

      it_behaves_like "API V3 collection response", 3, 3, "WikiPageLink", "WikiPageLinkCollection" do
        let(:elements) { Wikis::RelationPageLink.where.not(id: unaccessible_links.pluck(:id)).order(id: :desc).all }
      end

      it "only returns the filtered type" do
        json = MultiJson.load(last_response.body, symbolize_keys: true)

        expect(json.dig(:_embedded, :elements))
          .to all(include(wikiPageLinkType: API::V3::PageLinks::URN_PAGE_LINK_TYPE["Wikis::RelationPageLink"]))
      end
    end
  end

  describe "POST /api/v3/wiki_page_links" do
    let(:user) { create(:user, member_with_permissions: { project => %i(view_work_packages manage_wiki_page_links) }) }

    let(:path) { api_v3_paths.wiki_page_links }
    let(:author) { create(:user, member_with_permissions: { project => %i(view_work_packages) }) }

    let(:params) do
      { _type: "Collection", _embedded: { elements: embedded_elements } }
    end

    let(:external_wiki_element) do
      {
        identifier: "/wiki/path/to/kiwi",
        type: "urn:openproject-org:api:v3:wikiPageLinks:Relation",
        author: { href: api_v3_paths.user(author.id) },
        linkable: { href: api_v3_paths.work_package(work_package.id) },
        provider: { href: api_v3_paths.wiki_provider(xwiki_provider.universal_identifier) }
      }
    end

    let(:other_work_package) { create(:work_package, project:) }
    let(:internal_wiki_element) do
      {
        identifier: "/wiki/anotherWiki/Waka/Waka",
        type: "urn:openproject-org:api:v3:wikiPageLinks:Relation",
        author: { href: api_v3_paths.user(author.id) },
        linkable: { href: api_v3_paths.work_package(other_work_package.id) },
        provider: { href: api_v3_paths.wiki_provider(internal_wiki.universal_identifier) }
      }
    end

    let(:embedded_elements) { [external_wiki_element, internal_wiki_element] }

    let(:response_body) { last_response.body }

    before do
      post path, params.to_json
    end

    context "when all embedded elements are valid" do
      it_behaves_like "API V3 collection response", 2, 2, "WikiPageLink", "WikiPageLinkCollection" do
        let(:elements) { Wikis::PageLink.order(created_at: :asc).last(2) }
        let(:expected_status_code) { 201 }
      end
    end

    context "when some embedded elements are invalid" do
      let(:embedded_elements) do
        [
          internal_wiki_element,
          { identifier: "/wiki/path/to/invalid_page",
            provider: { href: "/api/v3/wiki_providers/-100" },
            linkable: { href: api_v3_paths.work_package(work_package.id) },
            author: { href: api_v3_paths.user(user.id) } }
        ]
      end

      it "does not create any records" do
        expect(last_response).to have_http_status(422)

        page_link = Wikis::PageLink.where(identifier: [internal_wiki_element["identifier"], "/wiki/path/to/invalid_page"])
        expect(page_link).to be_empty
      end

      it "contains the error" do
        json = MultiJson.load(response_body)

        expect(json["message"]).to match(/Wiki Provider does not exist/)
      end
    end

    context "when elements are empty" do
      let(:embedded_elements) { [] }

      it "returns a missing element error" do
        expect(last_response).to have_http_status(422)
        response_body = last_response.body

        expect(response_body).to be_json_eql("Error".to_json).at_path("_type")
        expect(response_body)
          .to be_json_eql("urn:openproject-org:api:v3:errors:PropertyMissingError".to_json).at_path("errorIdentifier")
      end
    end
  end

  describe "DELETE /api/v3/wiki_page_links/:wiki_page_link_id" do
    let(:page_link) { create(:relation_wiki_page_link, linkable: work_package, provider: internal_wiki) }
    let(:path) { api_v3_paths.wiki_page_link(page_link.id) }

    before { delete path }

    it "deletes the relation page link" do
      expect(last_response).to have_http_status(204)

      expect(Wikis::PageLink).not_to exist(page_link.id)
    end

    context "when called over an inline page links" do
      let(:page_link) { create(:inline_wiki_page_link, linkable: work_package, provider: internal_wiki) }

      it "returns a 404" do
        expect(last_response).to have_http_status(404)
      end
    end

    context "when the user lacks manage wiki page links permissions" do
      let(:user) { create(:user, member_with_permissions: { project => %i(view_work_packages) }) }

      it "checks if the user has manage page links permissions" do
        expect(last_response).to have_http_status(403)
      end
    end
  end

  private

  def stub_provider_queries
    internal_class = class_double(Wikis::Adapters::Providers::Internal::Queries::PageInfo)
    xwiki_class = class_double(Wikis::Adapters::Providers::XWiki::Queries::StablePageInfo)

    internal_query = instance_double(Wikis::Adapters::Providers::Internal::Queries::PageInfo)
    xwiki_query = instance_double(Wikis::Adapters::Providers::XWiki::Queries::StablePageInfo)

    Wikis::Adapters::Registry.stub("internal.queries.page_info", internal_class)
    Wikis::Adapters::Registry.stub("xwiki.queries.page_info", xwiki_class)

    allow(internal_class).to receive(:new).and_return(internal_query)
    allow(xwiki_class).to receive(:new).and_return(xwiki_query)
    stub_query_calls(inline_page_links, internal_query)
    stub_query_calls(relation_page_links, xwiki_query)
    stub_query_calls(unrelated_page_links, internal_query)
  end

  def stub_query_calls(links, query)
    links.each do |link|
      Wikis::Adapters::Input::PageInfo.build(identifier: link.identifier).bind do |input|
        allow(query).to receive(:call).with(input_data: input, auth_strategy: anything).and_return(Success(build_page_info(link)))
      end
    end
  end

  def build_page_info(link)
    Wikis::Adapters::Results::PageInfo.new(
      identifier: link.identifier, href: "valid_uri", title: "Title of #{link.identifier}", provider: link.provider
    )
  end
end
