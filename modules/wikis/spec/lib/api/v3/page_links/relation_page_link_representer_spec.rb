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
      RSpec.describe RelationPageLinkRepresenter, :rendering do
        include Utilities::PathHelper

        let(:current_user) { create(:user) }

        let(:relation_page_link) { build_stubbed(:relation_wiki_page_link) }
        let(:embed_links) { false }

        let(:represented) { relation_page_link }
        let(:project) { represented.linkable.project }

        let(:representer) { described_class.new(represented, current_user:, embed_links:) }

        subject(:resulting_json) { representer.to_json }

        describe "_links" do
          describe "author" do
            it_behaves_like "has a titled link" do
              let(:link) { "author" }
              let(:href) { "/api/v3/users/#{represented.author_id}" }
              let(:title) { represented.author.name }
            end
          end

          describe "delete" do
            let(:permission) { :manage_wiki_page_links }

            let(:link) { "delete" }
            let(:href) { "/api/v3/wiki_page_links/#{represented.id}" }
            let(:method) { :delete }

            it_behaves_like "has an untitled action link"

            context "when there is no associated linkable" do
              before { represented.linkable = nil }

              it_behaves_like "has no link"
            end
          end
        end

        describe "properties" do
          it_behaves_like "property", :wikiPageLinkType do
            let(:value) { URN_RELATION_PAGE_LINK }
          end
        end

        describe ".from_hash" do
          let(:author) { current_user }
          let(:author_href) { api_v3_paths.user(author.id) }

          let(:work_package) { create(:work_package) }
          let(:work_package_href) { api_v3_paths.work_package(work_package.id) }

          let(:provider) { create(:xwiki_provider) }

          let(:hash) do
            { wiki_page_type: API::V3::PageLinks::URN_PAGE_LINK_TYPE["Wikis::RelationPageLink"],
              identifier: "/an/actual/valid/page/identifier",
              _links: {
                author: { href: author_href },
                provider: { href: api_v3_paths.wiki_provider(provider.universal_identifier) },
                linkable: { href: work_package_href }
              } }.deep_stringify_keys
          end

          subject(:parsed) { described_class.new(ParserStruct.new, current_user:).from_hash(hash) }

          describe "author" do
            context "when the current user is not an admin and setting is off" do
              it "sets the author to the current user" do
                expect(parsed["author"]).to eq(current_user)
              end
            end

            context "when the current user is an admin" do
              let(:current_user) { create(:admin) }

              context "when the setting is apiv3_write_readonly_attributes disabled" do
                it "sets the author to the current user" do
                  expect(parsed["author"]).to eq(current_user)
                end
              end

              context "when the setting apiv3_write_readonly_attributes enabled",
                      with_settings: { apiv3_write_readonly_attributes: true } do
                context "and the author exists" do
                  it "sets the author to the provided user" do
                    expect(parsed["author"]).to eq(author)
                  end
                end

                context "when the author does not exist" do
                  let(:author_href) { api_v3_paths.user("abc") }

                  it "sets #author to an Inexistent User" do
                    expect(parsed["author"]).to eq(::Users::InexistentUser.new)
                  end
                end

                context "when the href can't be parsed" do
                  let(:author_href) { "/api/v3/foods/schnitzel" }

                  it "sets #author to an Inexistent User" do
                    expect(parsed["author"]).to be_nil
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
