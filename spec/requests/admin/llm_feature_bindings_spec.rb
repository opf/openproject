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

RSpec.describe "Admin AI model assignment", :llm_server_helpers, :skip_csrf, :webmock,
               type: :rails_request, with_flag: { llm_connection: true } do
  let(:admin) { create(:admin) }
  let(:base_url) { "https://example.com/v1" }

  describe "GET /admin/llm_feature_bindings" do
    before { login_as admin }

    it "prompts to configure a connection when there is none" do
      get llm_feature_bindings_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No LLM server configured")
    end

    context "with a configured connection" do
      let!(:connection) { create(:llm_connection, :with_models, base_url:) }

      it "lists every registered feature" do
        get llm_feature_bindings_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Description assistant")
        expect(response.body).to include("Semantic search")
      end

      # Hiding an unusable model is the one thing that produces an unanswerable
      # support question, so it stays listed and says why it cannot be chosen.
      it "offers a model with no verdict, marked as unverified" do
        get llm_feature_bindings_path

        expect(response.body).to include("qwen3.6-27b — not verified")
      end

      it "disables a model known not to support a required capability" do
        connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "embeddings",
                                               state: "unsupported", source: "probe", checked_at: Time.current)

        get llm_feature_bindings_path

        expect(response.body).to include("qwen3.6-27b — no Embeddings support")
      end
    end
  end

  describe "PATCH /admin/llm_feature_bindings/:id" do
    let!(:connection) { create(:llm_connection, :with_models, base_url:) }

    before { login_as admin }

    it "stores the chosen model" do
      patch llm_feature_binding_path("description_assistant"),
            params: { llm_feature_binding: { model_id: "qwen3.6-27b" } }

      expect(response).to have_http_status(:see_other)
      expect(connection.feature_bindings.find_by(feature_key: "description_assistant").model_id)
        .to eq("qwen3.6-27b")
    end

    it "treats a blank choice as inheriting the default" do
      connection.feature_bindings.create!(feature_key: "description_assistant", model_id: "qwen3.6-27b")

      patch llm_feature_binding_path("description_assistant"), params: { llm_feature_binding: { model_id: "" } }

      expect(connection.feature_bindings.find_by(feature_key: "description_assistant").model_id).to be_nil
    end

    # The verdict that matters is the one for the model just chosen, so it is
    # fetched now rather than left unknown until the feature first runs.
    it "probes the model when the feature requires a capability" do
      request = stub_request(:post, "#{base_url}/embeddings")
                  .to_return(status: 200,
                             headers: { "Content-Type" => "application/json" },
                             body: { data: [{ embedding: [0.1, 0.2] }] }.to_json)

      patch llm_feature_binding_path("semantic_search"), params: { llm_feature_binding: { model_id: "bge-m3" } }

      expect(request).to have_been_made.once
      verdict = connection.capability_verdicts.find_by(model_id: "bge-m3", capability: "embeddings")
      expect(verdict.state).to eq("supported")
      expect(verdict.dimensions).to eq(2)
    end

    it "does not probe for a feature that requires nothing" do
      patch llm_feature_binding_path("description_assistant"),
            params: { llm_feature_binding: { model_id: "qwen3.6-27b" } }

      expect(a_request(:post, "#{base_url}/embeddings")).not_to have_been_made
    end

    it "404s for a feature that is not registered" do
      patch llm_feature_binding_path("no_such_feature"), params: { llm_feature_binding: { model_id: "x" } }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "embedding settings" do
    let!(:connection) { create(:llm_connection, :with_models, :enabled, base_url:) }

    before do
      login_as admin
      # Binding an embedding feature probes the model for a vector.
      mock_llm_embeddings_response(base_url)
    end

    it "stores the vector settings, keeping the prefixes exactly as typed" do
      patch llm_feature_binding_path(:semantic_search),
            params: { llm_feature_binding: { model_id: "bge-m3",
                                             dimensions: "1024",
                                             input_prefix: "passage: ",
                                             query_prefix: "query: " } }

      binding = connection.feature_bindings.find_by(feature_key: "semantic_search")

      expect(binding.dimensions).to eq(1024)
      # The trailing space is load-bearing for the E5 and BGE families.
      expect(binding.input_prefix).to eq("passage: ")
      expect(binding.query_prefix).to eq("query: ")
    end

    it "rejects a dimension count that is not a positive integer" do
      patch llm_feature_binding_path(:semantic_search),
            params: { llm_feature_binding: { model_id: "bge-m3", dimensions: "0" } }

      expect(connection.feature_bindings.find_by(feature_key: "semantic_search")&.dimensions).to be_nil
    end

    it "ignores vector settings sent to a chat feature" do
      patch llm_feature_binding_path(:description_assistant),
            params: { llm_feature_binding: { model_id: "qwen3.6-27b", dimensions: "1024" } }

      binding = connection.feature_bindings.find_by(feature_key: "description_assistant")

      expect(binding.model_id).to eq("qwen3.6-27b")
      expect(binding.dimensions).to be_nil
    end

    # A locked binding is the record that a vector index exists. Everything the
    # index depends on is frozen, not just the model.
    it "refuses to change anything a locked index depends on" do
      binding = connection.feature_bindings.create!(feature_key: "semantic_search", model_id: "bge-m3",
                                                    dimensions: 1024, input_prefix: "passage: ",
                                                    locked_at: Time.current)

      patch llm_feature_binding_path(:semantic_search),
            params: { llm_feature_binding: { model_id: "bge-m3", dimensions: "512", input_prefix: "other: " } }

      binding.reload
      expect(binding.dimensions).to eq(1024)
      expect(binding.input_prefix).to eq("passage: ")
    end
  end
end
