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

module API
  module V3
    module PageLinks
      RSpec.describe PageLinkRepresenter, :rendering do
        include Utilities::PathHelper

        let(:inline_page_link) { build_stubbed(:inline_wiki_page_link) }
        let(:current_user) { create(:user) }

        let(:represented) { inline_page_link }
        let(:project) { represented.linkable.project }

        let(:embed_links) { false }
        let(:representer) { described_class.new(represented, current_user:, embed_links:) }

        subject(:resulting_json) { representer.to_json }

        describe "_links" do
          describe "self" do
            it_behaves_like "has a titled link" do
              let(:link) { "self" }
              let(:href) { "/api/v3/wiki_page_links/#{represented.id}" }
              let(:title) { represented.identifier }
            end
          end

          describe "provider" do
            it_behaves_like "has a titled link" do
              let(:link) { "provider" }
              let(:href) { "/api/v3/wiki_providers/#{represented.provider.universal_identifier}" }
              let(:title) { represented.provider.name }
            end
          end

          describe "linkable" do
            it_behaves_like "has a titled link" do
              let(:link) { "linkable" }
              let(:href) { "/api/v3/work_packages/#{represented.linkable_id}" }
              let(:title) { represented.linkable.name }
            end
          end
        end

        describe "properties" do
          it_behaves_like "property", :wikiPageLinkType do
            let(:value) { URN_INLINE_PAGE_LINK }
          end

          it_behaves_like "property", :_type do
            let(:value) { "WikiPageLink" }
          end

          it_behaves_like "property", :identifier do
            let(:value) { represented.identifier }
          end

          it_behaves_like "datetime property", :createdAt do
            let(:value) { represented.created_at }
          end

          it_behaves_like "datetime property", :updatedAt do
            let(:value) { represented.updated_at }
          end
        end

        describe ".from_hash" do
          let(:provider) { create(:xwiki_provider) }
          let(:provider_href) { api_v3_paths.wiki_provider(provider.universal_identifier) }

          let(:author) { current_user }
          let(:author_href) { api_v3_paths.user(author.id) }

          let(:work_package) { create(:work_package) }
          let(:work_package_href) { api_v3_paths.work_package(work_package.id) }

          let(:hash) do
            { wiki_page_type: API::V3::PageLinks::URN_PAGE_LINK_TYPE["Wikis::RelationPageLink"],
              identifier: "/an/actual/valid/page/identifier",
              _links: {
                provider: { href: provider_href, title: provider.name },
                linkable: { href: work_package_href }
              } }.deep_stringify_keys
          end

          subject(:parsed) { described_class.new(ParserStruct.new, current_user:).from_hash(hash) }

          describe "provider" do
            context "when the provider exists" do
              it "sets #provider to the correct provider" do
                expect(parsed.provider).to eq(provider)
              end
            end

            context "when the provider does not exist" do
              let(:provider_href) { "/api/v3/wiki_providers/-100" }

              it "sets #provider to an Inexistent provider" do
                expect(parsed.provider).to be_a(Wikis::InexistentProvider)
              end
            end

            context "when the link can't be parsed" do
              let(:provider_href) { api_v3_paths.user(current_user) }

              it "sets #provider to nil" do
                expect(parsed.provider).to be_nil
              end
            end
          end
        end
      end
    end
  end
end
