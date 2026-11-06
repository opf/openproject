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

RSpec.describe "Search page with semantic search", :skip_csrf,
               type: :rails_request,
               with_flag: { llm_connection: true, semantic_search: true },
               with_settings: { llm_features_enabled: true } do
  let(:admin) { create(:admin) }
  let(:project) { create(:project) }

  let(:semantic_index) { create(:semantic_index, state: "ready") }

  before do
    create(:llm_feature_binding,
           llm_connection: create(:llm_connection, :with_models),
           feature_key: "semantic_search",
           semantic_index:)

    login_as admin
  end

  def get_search_page(**params)
    get search_path(project, { q: "login problems", filter: "work_packages", scope: "all" }.merge(params))
  end

  def component_tag
    page.find("opce-global-search-work-packages")
  end

  it "marks semantic search as available and maps search_mode=semantic" do
    get_search_page(search_mode: "semantic")

    expect(component_tag["data-semantic-search-available"]).to eq "true"
    expect(component_tag["data-search-mode"]).to eq '"semantic"'
  end

  it "defaults to text search mode without search_mode param" do
    get_search_page

    expect(component_tag["data-search-mode"]).to eq '"text"'
  end

  context "with the feature flag off", with_flag: { semantic_search: false } do
    it "marks semantic search as unavailable and uses text search" do
      get_search_page(search_mode: "semantic")

      expect(component_tag["data-semantic-search-available"]).to eq "false"
      expect(component_tag["data-search-mode"]).to eq '"text"'
    end
  end

  context "when pgvector is unavailable" do
    before do
      allow(OpenProject::Llm::Pgvector).to receive(:available?).and_return(false)
    end

    it "marks semantic search as unavailable and uses text search" do
      get_search_page(search_mode: "semantic")

      expect(component_tag["data-semantic-search-available"]).to eq "false"
      expect(component_tag["data-search-mode"]).to eq '"text"'
    end
  end
end
