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
  module Adapters
    module Providers
      module Internal
        module Queries
          RSpec.describe BrowsePages do
            shared_let(:internal_provider) { create(:internal_wiki_provider) }
            shared_let(:project) { create(:project, :with_internal_wiki) }

            shared_let(:wiki) { project.wiki }
            shared_let(:pages) { create_list(:wiki_page, 2, wiki:) }
            shared_let(:sub_pages) do
              parent = pages.first
              first_child = create(:wiki_page, wiki:).tap { it.update!(parent:) }
              second_child = create(:wiki_page, wiki:).tap { it.update!(parent: first_child) }

              [first_child, second_child]
            end

            let(:user) { create(:user, member_with_permissions: { project => [:view_wiki_pages] }) }

            let(:input_data) { Input::BrowsePages.build(parent_identifier:).value! }
            let(:auth_strategy) { internal_provider.auth_strategy_for(user).value! }

            subject(:query) { described_class.new(model: internal_provider) }

            context "when identifier is nil" do
              let(:parent_identifier) { nil }

              it "succeeds" do
                expect(query.call(auth_strategy:, input_data:)).to be_success
              end

              it "returns the wikis and root pages" do
                hierarchies = query.call(auth_strategy:, input_data:).value!

                expected_hierarchies = pages.map do |page|
                  PageHierarchy.wiki_page_to_page_hierarchy(page, provider: internal_provider)
                end

                expect(hierarchies).to all(be_a(Results::PageHierarchy))
                expect(hierarchies).to match_array(expected_hierarchies)
              end
            end

            context "when a page with the passed identifier exists" do
              let(:parent_identifier) { pages.first.id.to_s }

              it "succeeds" do
                expect(query.call(auth_strategy:, input_data:)).to be_success
              end

              it "returns all children pages of said page" do
                hierarchies = query.call(auth_strategy:, input_data:).value!

                expect(hierarchies).to all(be_a(Results::PageHierarchy))
                expect(hierarchies.size).to eq(1)

                expected_hierarchies = [PageHierarchy.wiki_page_to_page_hierarchy(sub_pages.first, provider: internal_provider)]
                expect(hierarchies).to match_array(expected_hierarchies)
              end
            end

            context "when a page with the passed identifier does not exist" do
              let(:parent_identifier) { "matte-blue-banana" }

              it "returns an empty list" do
                hierarchies = query.call(auth_strategy:, input_data:).value!
                expect(hierarchies).to be_empty
              end
            end
          end
        end
      end
    end
  end
end
