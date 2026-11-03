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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe "Semantic search in the global search", :js,
               with_flag: { llm_connection: true, semantic_search: true },
               with_settings: { llm_features_enabled: true } do
  create_shared_association_defaults_for_work_package_factory

  let(:admin) { create(:admin) }
  let(:project) { create(:project) }

  # No textual overlap with the query: only its embedding can match.
  let(:similar_wp) { create(:work_package, project:, subject: "Users cannot sign in") }
  # Matches the query textually, but its embedding is far away.
  let(:text_match_wp) { create(:work_package, project:, subject: "Login problems handbook") }

  let(:semantic_index) { create(:semantic_index, state: "ready") }

  before do
    create(:llm_feature_binding,
           llm_connection: create(:llm_connection, :with_models),
           feature_key: "semantic_search",
           semantic_index:)
    create(:work_package_embedding, work_package: similar_wp, semantic_index:, embedding: [0.1, 0.2, 0.3])
    create(:work_package_embedding, work_package: text_match_wp, semantic_index:, embedding: [-0.1, -0.2, -0.3])

    allow(Llm::WorkPackages::SemanticSearch).to receive(:query_vector)
      .and_return(WorkPackageEmbedding.vector_literal([0.1, 0.2, 0.3]))

    login_as(admin)
  end

  def search_work_packages_page
    visit search_path(q: "login problems", filter: "work_packages", scope: "all", search_mode: "semantic")
    Pages::EmbeddedWorkPackagesTable.new(find(".work-packages-embedded-view--container"))
  end

  it "finds work packages by meaning" do
    table = search_work_packages_page

    expect(page).to have_css("opce-global-search-work-packages[data-semantic-search-available='true']")
    expect(page).to have_css('opce-global-search-work-packages[data-search-mode=\'"semantic"\']')
    table.expect_work_package_subject(similar_wp.subject)
    table.ensure_work_package_not_listed!(text_match_wp)
  end

  context "with the feature flag off", with_flag: { semantic_search: false } do
    it "does not offer semantic search and falls back to text search" do
      table = search_work_packages_page

      expect(page).to have_css("opce-global-search-work-packages[data-semantic-search-available='false']")
      expect(page).to have_css('opce-global-search-work-packages[data-search-mode=\'"text"\']')
      table.expect_work_package_subject(text_match_wp.subject)
      table.ensure_work_package_not_listed!(similar_wp)
    end
  end

  context "when pgvector is unavailable" do
    before do
      allow(OpenProject::Llm::Pgvector).to receive(:available?).and_return(false)
    end

    it "does not offer semantic search and falls back to text search" do
      table = search_work_packages_page

      expect(page).to have_css("opce-global-search-work-packages[data-semantic-search-available='false']")
      expect(page).to have_css('opce-global-search-work-packages[data-search-mode=\'"text"\']')
      table.expect_work_package_subject(text_match_wp.subject)
      table.ensure_work_package_not_listed!(similar_wp)
    end
  end
end
