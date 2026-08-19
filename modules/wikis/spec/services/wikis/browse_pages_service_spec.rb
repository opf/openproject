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

module Wikis
  RSpec.describe BrowsePagesService, :webmock do
    shared_let(:internal_provider) { create(:internal_wiki_provider) }
    shared_let(:project) { create(:project, :with_internal_wiki, name: "DS Maintenance Shaft") }
    shared_let(:user) { create(:user, member_with_permissions: { project => [:view_wiki_pages] }) }
    shared_let(:xwiki_provider) { create(:xwiki_provider, :for_local_connection, connected_user: user) }

    subject(:service) { described_class.new(provider:, user:) }

    context "when identifier is blank" do
      let(:parent_identifier) { nil }

      context "when using the internal provider" do
        let(:pages) { create_list(:wiki_page, 2, wiki: project.wiki) }
        let(:provider) { internal_provider }

        before { pages }

        it "returns a wiki node named after the project" do
          page_tree = service.call(parent_identifier).value!

          expect(page_tree.size).to eq(1)
          expect(page_tree[0].type).to eq(:wiki)
          expect(page_tree[0].name).to eq("DS Maintenance Shaft")
        end

        it "returns the root pages for the returned wiki(s)" do
          page_tree = service.call(parent_identifier).value!
          wiki_entry = page_tree[0]

          expect(wiki_entry.children.size).to eq(2)
          expect(wiki_entry.children.map(&:type)).to match_array(%i[page page])
          expect(wiki_entry.children.map(&:children)).to contain_exactly([], [])
        end
      end

      context "when using the XWiki provider", vcr: "services/browse_pages_xwiki_nil_identifier" do
        let(:provider) { xwiki_provider }

        it "returns a wiki node" do
          page_tree = service.call(parent_identifier).value!

          expect(page_tree.size).to eq(1)
          expect(page_tree[0].type).to eq(:wiki)
          expect(page_tree[0].name).to eq("xwiki")
        end

        # The wiki structure here was
        # - xwiki
        #   - Cheesy Info
        #   - Help
        #   - Home
        #   - Sandbox
        it "returns the root pages for the existing wiki" do
          page_tree = service.call(parent_identifier).value!
          wiki_entry = page_tree[0]

          expect(wiki_entry.children.size).to eq(4)
          expect(wiki_entry.children.map(&:type)).to all(eq(:page))
          expect(wiki_entry.children.map(&:children)).to all(eq([]))
        end
      end
    end

    context "when the identifier is a valid" do
      context "when using the internal provider" do
        let(:parent_identifier) { pages.last.id.to_s }
        let(:pages) { create_list(:wiki_page, 2, wiki: project.wiki) }
        let(:provider) { internal_provider }

        before { pages }

        it "succeeds" do
          expect(service.call(parent_identifier)).to be_success
        end

        it "returns the identified page children entries" do
          create(:wiki_page, wiki: project.wiki, parent: pages.last)
          page_tree = service.call(parent_identifier).value!

          expect(page_tree.size).to eq(1)
          expect(page_tree.map(&:type)).to eq(%i[page])
        end
      end

      context "when using the XWiki provider", vcr: "services/browse_pages_xwiki_valid_identifier" do
        # This is a page stable id that has at least 1 child page
        let(:parent_identifier) { "31778" }
        let(:provider) { xwiki_provider }

        it "succeeds" do
          expect(service.call(parent_identifier)).to be_success
        end

        it "returns the identified page children entries" do
          page_tree = service.call(parent_identifier).value!

          expect(page_tree.size).to eq(1)
          expect(page_tree.map(&:type)).to eq(%i[page])
        end
      end
    end

    describe "error handling", vcr: "services/browse_pages_xwiki_not_found" do
      let(:parent_identifier) { "matte-banana-blue" }
      let(:provider) { create(:xwiki_provider, :for_local_connection, connected_user: user) }

      context "when the identifier does not exist" do
        it "returns an empty collection" do
          result = service.call(parent_identifier)

          expect(result).to be_success
          expect(result.value!).to be_empty
        end
      end
    end
  end
end
