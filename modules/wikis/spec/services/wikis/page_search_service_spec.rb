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
  let(:search_wikis) do
    instance_double(Wikis::Adapters::Providers::XWiki::Queries::SearchWikis, call: search_wikis_result)
  end
  let(:wikis) { [] }
  let(:search_wikis_result) { Success(wikis) }

  let(:page_info) { new_page_info(identifier: "42", title: "E-11 Training program", href: "#", provider:) }
  let(:page_info_result) { Success(page_info) }

  let(:page_hierarchies) do
    [
      new_page_hierarchy(
        page: new_page_info(identifier: "42", title: "E-11 Training program", href: "#", provider:),
        ancestors: [new_page_info(identifier: "41", title: "Stormtrooper space", href: "#", provider:)],
        wiki: new_wiki(identifier: "1", provider:, name: "Death Star", href: "#")
      ),
      new_page_hierarchy(
        page: new_page_info(identifier: "4", title: "Heat reactor", href: "#", provider:),
        ancestors: [],
        wiki: new_wiki(identifier: "2", provider:, name: "Starkiller Base", href: "#")
      )
    ]
  end

  let(:search_pages_result) { Success(page_hierarchies) }

  before do
    Wikis::Adapters::Registry.stub(
      "xwiki.queries.page_info_for_url",
      class_double(Wikis::Adapters::Providers::XWiki::Queries::PageInfoForUrl, new: page_info_for_url)
    )
    Wikis::Adapters::Registry.stub(
      "xwiki.queries.search_pages",
      class_double(Wikis::Adapters::Providers::XWiki::Queries::SearchPages, new: search_pages)
    )
    Wikis::Adapters::Registry.stub(
      "xwiki.queries.search_wikis",
      class_double(Wikis::Adapters::Providers::XWiki::Queries::SearchWikis, new: search_wikis)
    )
  end

  context "when the query is a normal search term" do
    let(:query) { "search term" }

    it "does not try to resolve the page by URL" do
      subject

      expect(page_info_for_url).not_to have_received(:call)
    end

    it "passes the search term along" do
      subject
      expect(search_pages).to have_received(:call).with(input_data: having_attributes(query:), auth_strategy: anything)
    end

    it "returns an array of trees as a result" do
      expect(subject).to be_success
      search_results = subject.value!

      expect(search_results).to be_a(Array)
      expect(search_results).not_to be_empty
      expect(search_results.first).to be_a(Wikis::Adapters::Results::PageSearchTreeNode)
    end

    it "has wiki root nodes" do
      expect(subject).to be_success
      search_results = subject.value!

      expect(search_results.size).to eq(2)
      expect(search_results[0].type).to eq(:wiki)
      expect(search_results[0].identifier).to eq(page_hierarchies[0].wiki.identifier)
      expect(search_results[1].type).to eq(:wiki)
      expect(search_results[1].identifier).to eq(page_hierarchies[1].wiki.identifier)
    end

    it "has ancestor nodes" do
      expect(subject).to be_success
      search_results = subject.value!

      ancestor_page = search_results[0].children[0]
      expect(ancestor_page.type).to eq(:page)
      expect(ancestor_page.identifier).to eq(page_hierarchies[0].ancestors[0].identifier)
    end

    it "has the search result nodes below their ancestors" do
      expect(subject).to be_success
      search_results = subject.value!

      first_page = search_results[0].children[0].children[0]
      expect(first_page.type).to eq(:page)
      expect(first_page.identifier).to eq(page_hierarchies[0].page.identifier)

      second_page = search_results[1].children[0]
      expect(second_page.type).to eq(:page)
      expect(second_page.identifier).to eq(page_hierarchies[1].page.identifier)
    end

    it "identifies every node by its type and identifier" do
      expect(subject).to be_success
      search_results = subject.value!

      key = Wikis::Adapters::Results::PageSearchTreeNode::NodeKey

      expect(search_results[0].key)
        .to eq(key.new(type: :wiki, identifier: page_hierarchies[0].wiki.identifier))
      expect(search_results[1].children[0].key)
        .to eq(key.new(type: :page, identifier: page_hierarchies[1].page.identifier))
    end

    context "if the search results contains an ancestor of another contained page" do
      let(:page) { new_page_info(identifier: "42", title: "E-11 Training program", href: "#", provider:) }
      let(:ancestor) { new_page_info(identifier: "41", title: "Stormtrooper space", href: "#", provider:) }
      let(:page_hierarchies) do
        wiki = new_wiki(identifier: "1", provider:, name: "Death Star", href: "#")

        [
          new_page_hierarchy(page: page, ancestors: [ancestor], wiki:),
          new_page_hierarchy(page: ancestor, ancestors: [], wiki:)
        ]
      end

      it "inserts the ancestor only once" do
        expect(subject).to be_success
        search_results = subject.value!

        expect(search_results[0].children.size).to eq(1)

        ancestor_node = search_results[0].children[0]
        expect(ancestor_node.type).to eq(:page)
        expect(ancestor_node.identifier).to eq(ancestor.identifier)

        page_node = ancestor_node.children[0]
        expect(page_node.type).to eq(:page)
        expect(page_node.identifier).to eq(page.identifier)
      end
    end

    context "if the search result is empty" do
      let(:page_hierarchies) { [] }

      it "returns an empty array" do
        expect(subject).to be_success
        expect(subject.value!).to be_empty
      end
    end

    context "if a wiki is matched by its own name" do
      let(:matched_wiki) { new_wiki(identifier: "9", provider:, name: "Demo project", href: "#") }
      let(:wikis) { [matched_wiki] }
      let(:page_hierarchies) { [] }

      it "passes the search term along" do
        subject
        expect(search_wikis).to have_received(:call).with(input_data: having_attributes(query:), auth_strategy: anything)
      end

      it "adds it as a standalone wiki node with no pages" do
        expect(subject).to be_success
        search_results = subject.value!

        expect(search_results.size).to eq(1)
        expect(search_results[0].type).to eq(:wiki)
        expect(search_results[0].identifier).to eq(matched_wiki.identifier)
        expect(search_results[0].children).to be_empty
      end
    end

    context "if a wiki is matched both by its name and through one of its pages" do
      let(:wiki) { new_wiki(identifier: "1", provider:, name: "Death Star", href: "#") }
      let(:wikis) { [wiki] }
      let(:page_hierarchies) do
        [
          new_page_hierarchy(
            page: new_page_info(identifier: "42", title: "E-11 Training program", href: "#", provider:),
            ancestors: [],
            wiki:
          )
        ]
      end

      it "inserts the wiki only once and keeps its page" do
        expect(subject).to be_success
        search_results = subject.value!

        expect(search_results.size).to eq(1)
        expect(search_results[0].identifier).to eq(wiki.identifier)
        expect(search_results[0].children.map(&:identifier)).to eq(["42"])
      end
    end

    context "if searching for wikis fails" do
      let(:search_wikis_result) { Failure(SimpleError.new(code: :unexpected, source: self)) }

      it "returns that error" do
        expect(subject).to eq(search_wikis_result)
      end
    end
  end

  context "when the query is a URL" do
    let(:query) { "https://example.com" }

    it "does not try to resolve a search query" do
      subject

      expect(search_pages).not_to have_received(:call)
    end

    it "returns a single page node as a result" do
      expect(subject).to be_success

      search_results = subject.value!
      expect(search_results).to be_a(Array)
      expect(search_results.size).to eq(1)
      expect(search_results.first.identifier).to eq(page_info.identifier)
      expect(search_results.first.type).to eq(:page)
      expect(search_results.first.name).to eq(page_info.title)
      expect(search_results.first.children).to be_empty
    end

    it "passes the URL along" do
      subject
      expect(page_info_for_url).to have_received(:call).with(input_data: having_attributes(url: query), auth_strategy: anything)
    end

    context "and when no page with the URL can be found" do
      let(:page_info_result) { Failure(SimpleError.new(code: :not_found, source: self)) }

      it "returns an empty success" do
        expect(subject).to eq(Success([]))
      end
    end

    context "and when finding the page by URL fails" do
      let(:page_info_result) { Failure(SimpleError.new(code: :unexpected, source: self)) }

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
      expect(subject.value!.size).to eq(2)
    end
  end

  private

  def new_page_info(identifier:, title:, href:, provider:)
    Wikis::Adapters::Results::PageInfo.new(identifier:, title:, href:, provider:)
  end

  def new_page_hierarchy(page:, ancestors:, wiki:)
    Wikis::Adapters::Results::PageHierarchy.new(page:, ancestors:, wiki:)
  end

  def new_wiki(identifier:, name:, href:, provider:)
    Wikis::Adapters::Results::Wiki.new(identifier:, name:, href:, provider:)
  end
end
