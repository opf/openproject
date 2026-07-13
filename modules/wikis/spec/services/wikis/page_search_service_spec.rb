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

RSpec.describe Wikis::PageSearchService do
  subject { described_class.new(provider:, user:).search_pages(query) }

  let(:provider) { create(:xwiki_provider, :with_connected_user, connected_user: user) }
  let(:user) { create(:user) }

  let(:page_info_for_url) do
    instance_double(Wikis::Adapters::Providers::XWiki::Queries::PageInfoForUrl, call: page_info_result)
  end
  let(:search_pages) do
    instance_double(Wikis::Adapters::Providers::XWiki::Queries::SearchPages, call: search_pages_result)
  end

  let(:page_info_result) { Success("a single page info") }
  let(:search_pages_result) { Success(["a lot of page infos"]) }

  before do
    Wikis::Adapters::Registry.stub(
      "xwiki.queries.page_info_for_url",
      class_double(Wikis::Adapters::Providers::XWiki::Queries::PageInfoForUrl, new: page_info_for_url)
    )
    Wikis::Adapters::Registry.stub(
      "xwiki.queries.search_pages",
      class_double(Wikis::Adapters::Providers::XWiki::Queries::SearchPages, new: search_pages)
    )
  end

  context "when the query is a normal search term" do
    let(:query) { "search term" }

    it "does not try to resolve the page by URL" do
      subject

      expect(page_info_for_url).not_to have_received(:call)
    end

    it "returns the result of search pages" do
      expect(subject).to be_success
      expect(subject.value!).to eq(["a lot of page infos"])
    end

    it "passes the search term along" do
      subject
      expect(search_pages).to have_received(:call).with(input_data: having_attributes(query:), auth_strategy: anything)
    end
  end

  context "when the query is a URL" do
    let(:query) { "https://example.com" }

    it "does not try to resolve a search query" do
      subject

      expect(search_pages).not_to have_received(:call)
    end

    it "resolves the page by URL" do
      expect(subject).to be_success
      expect(subject.value!).to be_a(Array)
      expect(subject.value!).to eq(["a single page info"])
    end

    it "passes the URL along" do
      subject
      expect(page_info_for_url).to have_received(:call).with(input_data: having_attributes(url: query), auth_strategy: anything)
    end

    context "and when no page with the URL can be found" do
      let(:page_info_result) { Failure(Wikis::Adapters::Results::Error.new(code: :not_found, source: self)) }

      it "returns the :not_found result (no attempt to perform a full text search)" do
        expect(subject).to eq(page_info_result)
      end
    end

    context "and when finding the page by URL fails" do
      let(:page_info_result) { Failure(Wikis::Adapters::Results::Error.new(code: :unexpected, source: self)) }

      it "returns an error" do
        expect(subject).to eq(page_info_result)
      end
    end
  end

  context "when the query contains a URL in the search term" do
    let(:query) { "https://example.com does not load" }

    it "does not try to resolve the page by URL" do
      subject

      expect(page_info_for_url).not_to have_received(:call)
    end

    it "returns the result of search pages" do
      expect(subject).to be_success
      expect(subject.value!).to eq(["a lot of page infos"])
    end
  end
end
