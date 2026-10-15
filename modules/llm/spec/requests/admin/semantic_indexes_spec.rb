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

RSpec.describe "Admin semantic indexes", :skip_csrf,
               type: :rails_request, with_flag: { llm_connection: true, semantic_search: true },
               with_settings: { llm_features_enabled: true } do
  include_context "with an embedding model offered"

  shared_let(:admin) { create(:admin) }

  let(:turbo_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }
  let(:valid_params) do
    { semantic_index: { title: "Nomic small", description: "Trial", model_id: "bge-m3",
                        embedding_vector_dimensions: 768, context_token_length: 2048 } }
  end

  before { login_as admin }

  describe "with the semantic search flag off", with_flag: { llm_connection: true, semantic_search: false } do
    it "does not expose the endpoints" do
      get new_dialog_semantic_indexes_path
      expect(response).to have_http_status(:not_found)

      post semantic_indexes_path, params: valid_params
      expect(response).to have_http_status(:not_found)
      expect(SemanticIndex.count).to eq(0)
    end
  end

  describe "as a non-admin" do
    before { login_as create(:user) }

    it "refuses to create a set" do
      post semantic_indexes_path, params: valid_params

      expect(response).to have_http_status(:forbidden)
      expect(SemanticIndex.count).to eq(0)
    end
  end

  describe "GET /admin/llm_feature_bindings" do
    it "lists the semantic indexes below the features" do
      create(:semantic_index, title: "Qwen3 baseline")

      get llm_feature_bindings_path

      expect(response).to have_http_status(:ok)
      expect(page).to have_test_selector("llm-semantic-index--box", text: "Qwen3 baseline")
      expect(page).to have_test_selector("llm-semantic-index--box", text: "Not indexed")
    end

    it "hides the box without the semantic search flag", with_flag: { llm_connection: true, semantic_search: false } do
      get llm_feature_bindings_path

      expect(page).to have_no_test_selector("llm-semantic-index--box")
    end
  end

  describe "GET new_dialog" do
    it "offers only embedding models" do
      get new_dialog_semantic_indexes_path, headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Semantic Index")

      items = Nokogiri::HTML(response.parsed_body).at_css("opce-autocompleter")["data-items"]
      expect(JSON.parse(items).pluck("id")).to contain_exactly("bge-m3")
    end
  end

  describe "POST /admin/semantic_indexes" do
    it "creates the set and returns to the feature configuration" do
      post semantic_indexes_path, params: valid_params

      expect(response).to redirect_to(llm_feature_bindings_path)
      expect(SemanticIndex.sole).to have_attributes(title: "Nomic small", model_id: "bge-m3",
                                                    embedding_vector_dimensions: 768,
                                                    context_token_length: 2048, state: "not_indexed")
    end

    it "re-renders the form with errors" do
      post semantic_indexes_path, params: { semantic_index: valid_params[:semantic_index].merge(model_id: "qwen3.6-27b") },
                                  headers: turbo_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("is not an embedding model offered by the configured LLM server.")
      expect(SemanticIndex.count).to eq(0)
    end
  end

  describe "existing set" do
    let!(:semantic_index) { create(:semantic_index, title: "Qwen3 baseline") }

    it "renders the edit dialog" do
      get edit_dialog_semantic_index_path(semantic_index), headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Edit &quot;Qwen3 baseline&quot;")
    end

    it "updates the set" do
      patch semantic_index_path(semantic_index),
            params: { semantic_index: { title: "Qwen3 production", context_token_length: 4096 } }

      expect(response).to redirect_to(llm_feature_bindings_path)
      expect(semantic_index.reload).to have_attributes(title: "Qwen3 production", context_token_length: 4096)
    end

    it "renders the deletion dialog" do
      get deletion_dialog_semantic_index_path(semantic_index), headers: turbo_headers

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Delete Qwen3 baseline?")
    end

    it "deletes the set" do
      delete semantic_index_path(semantic_index)

      expect(response).to redirect_to(llm_feature_bindings_path)
      expect(SemanticIndex.count).to eq(0)
    end
  end
end
