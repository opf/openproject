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

# Manual entry exists for servers that route /v1/chat/completions but expose no
# model list -- OpenProject's own hosted gateway does exactly that today.
RSpec.describe "Admin manual LLM models", :llm_server_helpers, :skip_csrf, :webmock, type: :rails_request do
  let(:admin) { create(:admin) }
  let(:base_url) { "https://example.com/v1" }
  let!(:connection) { create(:llm_connection, base_url:) }

  before { login_as admin }

  describe "POST /admin/llm_models" do
    it "adds a model an administrator names" do
      post llm_models_path, params: { llm_model: { external_id: "qwen3.6-35b-a3b" } }

      expect(response).to have_http_status(:see_other)
      llm_model = connection.models.find_by(external_id: "qwen3.6-35b-a3b")
      expect(llm_model).to be_manual
      expect(connection.available_model_ids).to include("qwen3.6-35b-a3b")
    end

    it "rejects a duplicate" do
      create(:llm_model, llm_connection: connection, external_id: "already-there")

      post llm_models_path, params: { llm_model: { external_id: "already-there" } }

      expect(connection.models.where(external_id: "already-there").count).to eq(1)
    end

    it "makes the model bindable straight away" do
      post llm_models_path, params: { llm_model: { external_id: "qwen3.6-35b-a3b" } }

      patch llm_feature_binding_path("description_assistant"),
            params: { llm_feature_binding: { model_id: "qwen3.6-35b-a3b" } }

      expect(connection.feature_bindings.find_by(feature_key: "description_assistant").model_id)
        .to eq("qwen3.6-35b-a3b")
    end
  end

  describe "a refresh that cannot see the manual model" do
    it "keeps it, and withdraws discovered models instead" do
      create(:llm_model, llm_connection: connection, external_id: "was-discovered")
      post llm_models_path, params: { llm_model: { external_id: "hand-typed" } }
      mock_llm_models_response(base_url)

      post refresh_models_llm_connection_path

      expect(connection.models.find_by(external_id: "hand-typed")).to be_active
      expect(connection.models.find_by(external_id: "was-discovered")).not_to be_active
      expect(connection.available_model_ids).to include("hand-typed", "qwen3.6-27b")
    end
  end

  describe "PATCH /admin/llm_models/:id" do
    let!(:llm_model) { create(:llm_model, :manual, llm_connection: connection, external_id: "hand-typed") }

    it "stores capabilities an administrator asserts" do
      patch llm_model_path(llm_model),
            params: { llm_model: { display_name: "Hand typed" },
                      capabilities: { embeddings: "supported", vision: "unsupported" } }

      expect(response).to have_http_status(:see_other)
      expect(llm_model.reload.display_name).to eq("Hand typed")

      verdicts = connection.capability_verdicts.for_model("hand-typed").pluck(:capability, :state, :source)
      expect(verdicts).to include(["embeddings", "supported", "admin"], ["vision", "unsupported", "admin"])
    end

    it "stores a context window an administrator supplies" do
      patch llm_model_path(llm_model), params: { llm_model: { admin_context_window: "32768" } }

      expect(llm_model.reload.context_window).to eq(32_768)
      expect(llm_model.context_window_source).to eq(:admin)
    end

    # The administrator's figure wins over whatever the server or a registry said.
    it "prefers the administrator's context window over a reported one" do
      llm_model.update!(raw_metadata: { "max_model_len" => 8192 })

      patch llm_model_path(llm_model), params: { llm_model: { admin_context_window: "32768" } }

      expect(llm_model.reload.context_window).to eq(32_768)
    end

    it "falls back to the reported figure when cleared" do
      llm_model.update!(raw_metadata: { "max_model_len" => 8192, "admin_context_window" => 32_768 })

      patch llm_model_path(llm_model), params: { llm_model: { admin_context_window: "" } }

      expect(llm_model.reload.context_window).to eq(8192)
      expect(llm_model.context_window_source).to eq(:server)
    end

    it "makes an asserted capability satisfy a feature that requires it" do
      patch llm_model_path(llm_model), params: { capabilities: { embeddings: "supported" } }

      patch llm_feature_binding_path("semantic_search"),
            params: { llm_feature_binding: { model_id: "hand-typed" } }

      expect(connection.feature_bindings.find_by(feature_key: "semantic_search").model_id).to eq("hand-typed")
    end

    # Clearing an assertion records nothing rather than recording ignorance as
    # fact, so detection can still fill it in later.
    it "clears an assertion when set back to unspecified" do
      patch llm_model_path(llm_model), params: { capabilities: { embeddings: "supported" } }
      patch llm_model_path(llm_model), params: { capabilities: { embeddings: "" } }

      expect(connection.capability_verdicts.for_model("hand-typed").for_capability(:embeddings)).to be_empty
    end

    # An administrator looked at this deployment; a published registry did not.
    it "is not overwritten by registry enrichment" do
      patch llm_model_path(llm_model), params: { capabilities: { embeddings: "supported" } }

      LlmConnections::EnrichCapabilitiesService.new(connection).call

      verdict = connection.capability_verdicts.find_by(model_id: "hand-typed", capability: "embeddings")
      expect(verdict.source).to eq("admin")
      expect(verdict.state).to eq("supported")
    end
  end

  describe "the model type shown in the list" do
    it "reads as an embedding model once embeddings are supported" do
      llm_model = create(:llm_model, :manual, llm_connection: connection, external_id: "bge-m3")
      patch llm_model_path(llm_model), params: { capabilities: { embeddings: "supported" } }

      get llm_connection_path

      expect(response.body).to include("Embedding")
    end

    it "reads as a chat model when embeddings are not supported" do
      llm_model = create(:llm_model, :manual, llm_connection: connection, external_id: "qwen")
      patch llm_model_path(llm_model), params: { capabilities: { embeddings: "unsupported" } }

      get llm_connection_path

      expect(response.body).to include("Chat")
    end
  end

  describe "DELETE /admin/llm_models/:id" do
    it "removes a manual model" do
      llm_model = create(:llm_model, :manual, llm_connection: connection, external_id: "hand-typed")

      delete llm_model_path(llm_model)

      expect(response).to have_http_status(:see_other)
      expect(LlmModel.where(id: llm_model.id)).to be_empty
    end

    # Discovered models are the server's to add and remove, not the administrator's.
    it "refuses to remove a discovered model" do
      llm_model = create(:llm_model, llm_connection: connection, external_id: "from-server")

      delete llm_model_path(llm_model)

      expect(response).to have_http_status(:not_found)
      expect(LlmModel.where(id: llm_model.id)).to exist
    end
  end
end
