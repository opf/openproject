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

RSpec.describe Wikis::Adapters::Providers::XWiki::Queries::ReferencingPages, :disable_ssrf_filter, :webmock do
  include XWikiStubs

  it "is registered" do
    expect(Wikis::Adapters::Registry.resolve("xwiki.queries.referencing_pages")).to eq(described_class)
  end

  describe "input validation" do
    it "rejects a linkable that is not a work package" do
      expect(Wikis::Adapters::Input::ReferencingPages.build(linkable: create(:project))).to be_failure
    end
  end

  describe "#call" do
    let(:user) { create(:user) }
    let(:wiki_provider) do
      create(:xwiki_provider, :with_connected_user, url: "https://xwiki.example.com/", connected_user: user)
    end
    let(:linkable) { create(:work_package) }
    let(:auth_strategy) do
      Wikis::Adapters::Input::AuthStrategy.build(key: :bearer_token, user:, provider: wiki_provider).value!
    end
    let(:input_data) { Wikis::Adapters::Input::ReferencingPages.build(linkable:).value! }
    let(:query) { described_class.new(model: wiki_provider) }
    let(:resolved_identifiers) { result.value!.map { it.value!.identifier } }

    subject(:result) { query.call(input_data:, auth_strategy:) }

    context "when the same page appears multiple times in results" do
      let(:duplicate_id) { "xwiki:Main.WebHome" }
      let(:same_title_different_id) { "xwiki:Other.WebHome" }

      before do
        stub_search(
          [
            { "id" => duplicate_id, "title" => "Home" },
            { "id" => duplicate_id, "title" => "Home" },
            { "id" => same_title_different_id, "title" => "Home" }
          ],
          provider: wiki_provider,
          linkable:
        )
        stub_mentions([], provider: wiki_provider, linkable:)
        stub_canonical_page_info(duplicate_id,
                                 uid: "aaa111",
                                 title: "Home",
                                 href: "https://xwiki.example.com/bin/view/Main/",
                                 provider: wiki_provider)
        stub_canonical_page_info(same_title_different_id,
                                 uid: "bbb222",
                                 title: "Home",
                                 href: "https://xwiki.example.com/bin/view/Other/",
                                 provider: wiki_provider)
      end

      it { is_expected.to be_success }

      it "deduplicates by page identifier, not by title" do
        expect(resolved_identifiers).to contain_exactly("aaa111", "bbb222")
      end
    end

    context "with a single page" do
      let(:page_id) { "xwiki:Main.WebHome" }

      before do
        stub_canonical_page_info(page_id,
                                 uid: "aaa111",
                                 title: "Home",
                                 href: "https://xwiki.example.com/bin/view/Main/",
                                 provider: wiki_provider)
      end

      context "when a page appears in both links and mentions" do
        before do
          stub_search([{ "id" => page_id, "title" => "Home" }], provider: wiki_provider, linkable:)
          stub_mentions([{ "id" => page_id }], provider: wiki_provider, linkable:)
        end

        it "returns the page only once" do
          expect(resolved_identifiers).to contain_exactly("aaa111")
        end
      end

      context "when pages appear only in mentions" do
        before do
          stub_search([], provider: wiki_provider, linkable:)
          stub_mentions([{ "id" => page_id }], provider: wiki_provider, linkable:)
        end

        it "includes pages from the mentions endpoint" do
          expect(resolved_identifiers).to contain_exactly("aaa111")
        end
      end

      context "when the mentions request fails" do
        before do
          stub_search([{ "id" => page_id, "title" => "Home" }], provider: wiki_provider, linkable:)
          stub_request(:get, mentions_endpoint(linkable, provider: wiki_provider))
            .to_return(status: 500, body: "Internal Server Error")
        end

        it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :request_failed)) }
      end
    end

    context "when the links request fails" do
      context "with a server error" do
        before do
          stub_request(:get, search_endpoint(linkable, provider: wiki_provider))
            .to_return(status: 500, body: "Internal Server Error")
        end

        it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :request_failed)) }
      end

      context "when unauthorized" do
        before { stub_request(:get, search_endpoint(linkable, provider: wiki_provider)).to_return(status: 401, body: "") }

        it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :unauthorized)) }
      end

      context "when timing out" do
        before { stub_request(:get, search_endpoint(linkable, provider: wiki_provider)).to_timeout }

        it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :connection_error)) }
      end
    end

    context "when no OAuth token exists for the user" do
      let(:wiki_provider) { create(:xwiki_provider, :with_oauth_client, url: "https://xwiki.example.com/") }

      it { is_expected.to be_failure.and have_attributes(failure: have_attributes(code: :missing_token)) }
    end

    context "with real XWiki responses", vcr: "xwiki/referencing_pages" do
      let(:wiki_provider) { create(:xwiki_provider, :for_local_connection, connected_user: user) }
      let(:linkable) { create(:work_package, id: 14) }
      let(:auth_strategy) { wiki_provider.auth_strategy_for(user).value! }

      it "returns PageInfo for all linked and mentioned pages" do
        expect(result).to be_success
        expect(result.value!.map { it.value!.to_h.except(:provider) }).to contain_exactly(
          { identifier: "48944", title: "OpenProject integration", href: "https://xwiki.local/bin/view/test/" },
          { identifier: "42f2f", title: "Def New Page", href: "https://xwiki.local/bin/view/test/Def%20New%20Page/" },
          { identifier: "a3739", title: "Just a normal page", href: "https://xwiki.local/bin/view/Just%20a%20normal%20page/" },
          { identifier: "f58c0", title: "Test reference", href: "https://xwiki.local/bin/view/Test%20reference/" }
        )
      end
    end

    context "with no linked pages in XWiki (VCR)", vcr: "xwiki/referencing_pages_empty" do
      let(:wiki_provider) { create(:xwiki_provider, :for_local_connection, connected_user: user) }
      let(:linkable) { create(:work_package, id: 21) }
      let(:auth_strategy) { wiki_provider.auth_strategy_for(user).value! }

      it "returns an empty list" do
        expect(result).to be_success
        expect(result.value!).to eq([])
      end
    end
  end
end
