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
      module XWiki
        module Queries
          RSpec.describe BrowsePages, :webmock do
            shared_let(:user) { create(:user) }
            shared_let(:xwiki_provider) { create(:xwiki_provider, :for_local_connection, connected_user: user) }

            let(:input_data) { Input::BrowsePages.build(parent_identifier:).value! }
            let(:auth_strategy) { xwiki_provider.auth_strategy_for(user).value! }

            subject(:query) { described_class.new(model: xwiki_provider) }

            context "when parent identifier is nil", vcr: "xwiki/browse_pages_nil_identifier" do
              let(:parent_identifier) { nil }

              it "succeeds" do
                expect(query.call(auth_strategy:, input_data:)).to be_success
              end

              it "returns all root pages from all wikis" do
                hierarchies = query.call(auth_strategy:, input_data:).value!

                expect(hierarchies).to all(be_a(Results::PageHierarchy))
                expect(hierarchies.map(&:ancestors)).to all(be_empty)
              end
            end

            context "when parent identifier exists", vcr: "xwiki/browse_pages_existing_identifier" do
              # This is a page stable id that has at least 1 child page
              let(:parent_identifier) { "31778" }

              it "succeeds" do
                expect(query.call(auth_strategy:, input_data:)).to be_success
              end

              it "returns all the child pages of said parent" do
                hierarchies = query.call(auth_strategy:, input_data:).value!

                expect(hierarchies).to all(be_a(Results::PageHierarchy))

                immediate_ancestor = hierarchies.map { it.ancestors.first.identifier }
                expect(immediate_ancestor).to all(eq(parent_identifier))
              end
            end

            context "when the parent identifier does not exist", vcr: "xwiki/browse_pages_nonexistent_identifier" do
              let(:parent_identifier) { "matte-banana-blue" }

              it "fails" do
                expect(query.call(auth_strategy:, input_data:)).to be_failure
              end

              it "returns a not found error" do
                failure = query.call(auth_strategy:, input_data:).failure
                expect(failure.code).to eq(:not_found)
              end
            end
          end
        end
      end
    end
  end
end
