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
RSpec.describe "Admin manual LLM models", :llm_server_helpers, :skip_csrf, :webmock,
               type: :rails_request, with_flag: { llm_connection: true } do
  let(:admin) { create(:admin) }
  let(:base_url) { "https://example.com/v1" }
  let!(:connection) { create(:llm_connection, base_url:) }

  before { login_as admin }

  describe "POST /admin/llm_models" do
    it "accepts everything the edit screen accepts" do
      post llm_models_path, params: { llm_model: { external_id: "bge-m3",
                                                   display_name: "BGE M3",
                                                   admin_context_window: "8192",
                                                   capability_embeddings: "supported",
                                                   capability_vision: "unsupported" } }

      llm_model = connection.models.find_by(external_id: "bge-m3")
      expect(llm_model.display_name).to eq("BGE M3")
      expect(llm_model.context_window).to eq(8192)

      verdicts = connection.capability_verdicts.for_model("bge-m3").pluck(:capability, :state, :source)
      expect(verdicts).to include(["embeddings", "supported", "admin"], ["vision", "unsupported", "admin"])
    end

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
            params: { llm_model: { display_name: "Hand typed",
                                   capability_embeddings: "supported",
                                   capability_vision: "unsupported" } }

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
      patch llm_model_path(llm_model), params: { llm_model: { capability_embeddings: "supported" } }

      patch llm_feature_binding_path("semantic_search"),
            params: { llm_feature_binding: { model_id: "hand-typed" } }

      expect(connection.feature_bindings.find_by(feature_key: "semantic_search").model_id).to eq("hand-typed")
    end

    # Clearing an assertion records nothing rather than recording ignorance as
    # fact, so detection can still fill it in later.
    it "clears an assertion when set back to unspecified" do
      patch llm_model_path(llm_model), params: { llm_model: { capability_embeddings: "supported" } }
      patch llm_model_path(llm_model), params: { llm_model: { capability_embeddings: "" } }

      expect(connection.capability_verdicts.for_model("hand-typed").for_capability(:embeddings)).to be_empty
    end

    # An administrator looked at this deployment; a published registry did not.
    it "is not overwritten by registry enrichment" do
      patch llm_model_path(llm_model), params: { llm_model: { capability_embeddings: "supported" } }

      LlmConnections::EnrichCapabilitiesService.new(connection).call

      verdict = connection.capability_verdicts.find_by(model_id: "hand-typed", capability: "embeddings")
      expect(verdict.source).to eq("admin")
      expect(verdict.state).to eq("supported")
    end
  end

  describe "the model type shown in the list" do
    it "reads as an embedding model once embeddings are supported" do
      llm_model = create(:llm_model, :manual, llm_connection: connection, external_id: "bge-m3")
      patch llm_model_path(llm_model), params: { llm_model: { capability_embeddings: "supported" } }

      get llm_connection_path

      expect(response.body).to include("Embedding")
    end

    it "reads as a chat model when embeddings are not supported" do
      llm_model = create(:llm_model, :manual, llm_connection: connection, external_id: "qwen")
      patch llm_model_path(llm_model), params: { llm_model: { capability_embeddings: "unsupported" } }

      get llm_connection_path

      expect(response.body).to include("Chat")
    end
  end

  describe "GET /admin/llm_models/new" do
    it "renders the add-model form" do
      get new_llm_model_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Model name")
    end

    it "re-renders with the error inline when the name is taken" do
      create(:llm_model, llm_connection: connection, external_id: "already-there")

      post llm_models_path, params: { llm_model: { external_id: "already-there" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(connection.models.where(external_id: "already-there").count).to eq(1)
    end
  end

  describe "GET /admin/llm_models/:id/delete_dialog" do
    it "offers a confirmation naming the features that would break" do
      llm_model = create(:llm_model, :manual, llm_connection: connection, external_id: "hand-typed")
      connection.feature_bindings.create!(feature_key: "description_assistant", model_id: "hand-typed")

      # Requested by the async-dialog Stimulus controller, which asks for a
      # turbo stream rather than HTML.
      get delete_dialog_llm_model_path(llm_model),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Description assistant")
    end
  end

  describe "renaming to a taken id" do
    it "re-renders the form with the error instead of failing" do
      create(:llm_model, llm_connection: connection, external_id: "taken")
      llm_model = create(:llm_model, :manual, llm_connection: connection, external_id: "mine")

      patch llm_model_path(llm_model), params: { llm_model: { external_id: "taken" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(llm_model.reload.external_id).to eq("mine")
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

  describe "POST /admin/llm_models/:id/toggle" do
    let!(:llm_model) { create(:llm_model, llm_connection: connection, external_id: "qwen3.6-27b") }

    it "hides the model from the pickers and puts it back" do
      post toggle_llm_model_path(llm_model)

      expect(response).to have_http_status(:ok)
      expect(llm_model.reload).to be_deactivated
      expect(connection.selectable_model_ids).not_to include("qwen3.6-27b")

      post toggle_llm_model_path(llm_model)

      expect(llm_model.reload).not_to be_deactivated
      expect(connection.selectable_model_ids).to include("qwen3.6-27b")
    end

    # Curation, not enforcement: a feature already pointing at the model keeps
    # resolving, so switching a row off cannot silently break anything.
    it "leaves an existing binding working" do
      connection.feature_bindings.create!(feature_key: "description_assistant", model_id: "qwen3.6-27b")

      post toggle_llm_model_path(llm_model)

      expect(connection.available_model_ids).to include("qwen3.6-27b")
    end

    it "refuses a model the server has withdrawn" do
      withdrawn = create(:llm_model, :withdrawn, llm_connection: connection, external_id: "gone")

      post toggle_llm_model_path(withdrawn)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(withdrawn.reload).not_to be_deactivated
    end

    it "is refused to a non-admin" do
      login_as create(:user)

      post toggle_llm_model_path(llm_model)

      expect(llm_model.reload).not_to be_deactivated
    end
  end

  describe "renaming a manually added model" do
    let!(:llm_model) do
      create(:llm_model, :manual, llm_connection: connection, external_id: "qwen/qwen3.6-35b-a3b")
    end

    before do
      connection.update!(default_chat_model_id: "qwen/qwen3.6-35b-a3b")
      connection.feature_bindings.create!(feature_key: "description_assistant",
                                          model_id: "qwen/qwen3.6-35b-a3b")
      connection.capability_verdicts.create!(model_id: "qwen/qwen3.6-35b-a3b", capability: "embeddings",
                                             state: "unsupported", source: "probe", checked_at: Time.current)
    end

    it "offers the identifier field on the edit page" do
      get edit_llm_model_path(llm_model)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("llm_model[external_id]")
    end

    it "does not offer it for a discovered model" do
      discovered = create(:llm_model, llm_connection: connection, external_id: "server-named")

      get edit_llm_model_path(discovered)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("llm_model[external_id]")
    end

    # A typo in a hand-typed identifier was previously only fixable by deleting
    # the model, which threw away everything asserted about it.
    it "renames it and carries every reference along" do
      patch llm_model_path(llm_model), params: { llm_model: { external_id: "qwen/qwen3.6-35b-a3b:bf16" } }

      expect(llm_model.reload.external_id).to eq("qwen/qwen3.6-35b-a3b:bf16")
      expect(connection.reload.default_chat_model_id).to eq("qwen/qwen3.6-35b-a3b:bf16")
      expect(connection.feature_bindings.first.model_id).to eq("qwen/qwen3.6-35b-a3b:bf16")
      expect(connection.capability_verdicts.first.model_id).to eq("qwen/qwen3.6-35b-a3b:bf16")
    end

    it "keeps the feature resolving afterwards", with_flag: { llm_connection: true } do
      connection.update!(enabled: true)

      patch llm_model_path(llm_model), params: { llm_model: { external_id: "qwen/qwen3.6-35b-a3b:bf16" } }

      expect(Llm::Runtime.for(:description_assistant).model_id).to eq("qwen/qwen3.6-35b-a3b:bf16")
    end

    it "follows a model a locked binding depends on" do
      binding = connection.feature_bindings.first
      binding.update!(locked_at: Time.current)

      patch llm_model_path(llm_model), params: { llm_model: { external_id: "qwen/qwen3.6-35b-a3b:bf16" } }

      expect(binding.reload.model_id).to eq("qwen/qwen3.6-35b-a3b:bf16")
    end

    # The server names its own models; renaming one here would only be undone by
    # the next refresh.
    it "refuses to rename a discovered model" do
      discovered = create(:llm_model, llm_connection: connection, external_id: "server-named")

      patch llm_model_path(discovered), params: { llm_model: { external_id: "renamed" } }

      expect(discovered.reload.external_id).to eq("server-named")
    end
  end

  describe "how an inherited capability verdict is shown" do
    let!(:llm_model) { create(:llm_model, :manual, llm_connection: connection, external_id: "qwen3.6-27b") }

    # The blank option used to read "Not specified" while the caption underneath
    # read "Currently Supported, from the model registry" -- two contradictory
    # statements about the same field.
    it "names the inherited value in the option itself" do
      connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "function_calling",
                                             state: "supported", source: "metadata", checked_at: Time.current)

      get edit_llm_model_path(llm_model)

      expect(response.body).to include("Supported (from the model registry)")
      expect(response.body).not_to include("Currently Supported")
    end

    it "falls back to Not specified when nothing is known" do
      get edit_llm_model_path(llm_model)

      expect(response.body).to include("Not specified")
    end

    # An administrator's own assertion is loaded into the field, so the blank
    # option must not claim it as inherited.
    it "does not present an administrator's own assertion as inherited" do
      connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "function_calling",
                                             state: "supported", source: "admin", checked_at: Time.current)

      get edit_llm_model_path(llm_model)

      expect(response.body).not_to include("Supported (set by an administrator)")
    end
  end
end
