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

RSpec.describe "Admin LLM models", :llm_server_helpers, :skip_csrf, :webmock,
               type: :rails_request, with_flag: { llm_connection: true },
               with_settings: { llm_features_enabled: true } do
  let(:admin) { create(:admin) }
  let(:base_url) { "https://example.com/v1" }

  # The picker is an autocompleter, so its options are serialised into the
  # element rather than rendered as markup.
  def offered_default_models(field = :default_chat_model_id, markup: page)
    element = markup.all("[data-test-selector='llm-connection--defaults-form'] opce-autocompleter")
                    .find { |node| node["data-input-name"].include?(field.to_s) }
    ids = JSON.parse(element["data-items"]).pluck("id").compact_blank

    LlmModel.where(id: ids).pluck(:external_id)
  end

  # Nokogiri does not descend into a <template>, which is where a turbo stream
  # carries its markup.
  def streamed_markup = Capybara.string(response.body.gsub(%r{</?template>}, ""))

  describe "with the feature flag off", with_flag: { llm_connection: false } do
    before { login_as admin }

    it "does not expose the endpoints" do
      get llm_models_path
      expect(response).to have_http_status(:not_found)

      post refresh_llm_models_path
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /admin/llm_models" do
    it "is not reachable for non-admins" do
      login_as create(:user)
      get llm_models_path

      expect(response).not_to have_http_status(:ok)
    end

    context "when logged in as admin" do
      before { login_as admin }

      it "lists the cached models without contacting the server" do
        create(:llm_connection, :with_models, base_url:)

        get llm_models_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("qwen3.6-27b")
        expect(a_request(:get, "#{base_url}/models")).not_to have_been_made
      end

      it "warns that the list predates the current settings" do
        connection = create(:llm_connection, :with_models, base_url:)
        connection.update!(connection_fingerprint: connection.settings_fingerprint)
        connection.update!(api_key: "rotated")

        get llm_models_path

        expect(response.body).to include("llm-models--stale")
      end

      it "does not warn while the list matches the settings" do
        connection = create(:llm_connection, :with_models, base_url:)
        connection.update!(connection_fingerprint: connection.settings_fingerprint)

        get llm_models_path

        expect(response.body).not_to include("llm-models--stale")
      end

      it "shows every model as either a chat or an embedding model" do
        connection = create(:llm_connection, base_url:)
        create(:llm_model, llm_connection: connection, external_id: "bge-m3")
        create(:llm_model, llm_connection: connection, external_id: "qwen3.6-27b")
        connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                               state: "supported", source: "probe", checked_at: Time.current)

        get llm_models_path

        expect(response.body).to include("Embedding")
        expect(response.body).to include("Chat")
        expect(response.body).not_to include("Unknown")
      end

      it "keeps a long model name readable through the truncation" do
        connection = create(:llm_connection, base_url:)
        long_name = "publisher/a-very-long-model-name-that-does-not-fit-the-column-32b-instruct-2026-05"
        create(:llm_model, llm_connection: connection, external_id: long_name)

        get llm_models_path

        expect(response.body).to include("Truncate-text--expandable")
        expect(response.body).to include("title=\"#{long_name}\"")
      end

      it "keeps the source label short and spells it out on hover" do
        connection = create(:llm_connection, base_url:)
        create(:llm_model, llm_connection: connection, external_id: "qwen3.6-27b")

        get llm_models_path

        cell = page.find(".op-border-box-grid__row-item.source")
        expect(cell[:class]).to include("-no-ellipsis")
        expect(cell.find(".Label").text).to eq("Server")
        expect(cell.find(".Label")[:title]).to eq("Reported by the server")
      end

      it "offers the default chat model next to the models it may be chosen from" do
        connection = create(:llm_connection, :with_models, base_url:)
        connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                               state: "supported", source: "probe", checked_at: Time.current)

        get llm_models_path

        expect(response.body).to include("Default models")
        # An embedding model is a different kind of model, not a chat choice.
        expect(offered_default_models).to contain_exactly("qwen3.6-27b")
      end

      it "asks for no default while the connection has no model to offer" do
        create(:llm_connection, base_url:)

        get llm_models_path

        expect(response.body).to include("No models available")
        expect(response.body).not_to include("Default models")
      end

      it "shows the default read-only when the environment owns the connection" do
        connection = create(:llm_connection, :with_models, base_url:)
        connection.update!(default_chat_model: connection.models.find_by(external_id: "qwen3.6-27b"))
        allow(Setting).to receive(:llm_connection).and_return({ "base_url" => base_url })

        get llm_models_path

        expect(response.body).to include("configured via environment variables")
        expect(page).to have_css("[data-test-selector='llm-connection--defaults-form'] opce-autocompleter[data-disabled='true']")
        expect(page).to have_no_button("Save")
      end

      it "offers only models known to embed as the default embedding model" do
        connection = create(:llm_connection, :with_models, base_url:)
        connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                               state: "supported", source: "probe", checked_at: Time.current)

        get llm_models_path

        expect(offered_default_models(:default_embedding_model_id)).to contain_exactly("bge-m3")
        expect(response.body).to include("huggingface.co/blog/getting-started-with-embeddings")
      end

      # An unconfirmed capability is not a capability: offering such a model
      # invites a choice that fails much later, at index time.
      it "says how to make a model eligible while none is known to embed" do
        create(:llm_connection, :with_models, base_url:)

        get llm_models_path

        expect(response.body).to include("set its type to Embedding model")
      end

      # Switched off is a different problem from unqualified: the model does embed,
      # an administrator simply hid it, and saying otherwise sends them to the
      # model form to fix a type that is already right.
      it "tells a switched-off embedding default apart from an unqualified one" do
        connection = create(:llm_connection, :with_models, base_url:)
        connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                               state: "supported", source: "probe", checked_at: Time.current)
        connection.update_column(:default_embedding_model_id, connection.models.find_by(external_id: "bge-m3").id)
        connection.models.find_by(external_id: "bge-m3").update!(deactivated_at: Time.current)

        get llm_models_path

        expect(offered_default_models(:default_embedding_model_id)).to include("bge-m3")
        expect(response.body).to include("switched off")
        expect(response.body).not_to include("not known to create embeddings")
      end

      # The remedy the caption names is only the right one while nothing embeds.
      it "keeps the documentation caption while a known embedding model is switched off" do
        connection = create(:llm_connection, :with_models, base_url:)
        connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                               state: "supported", source: "probe", checked_at: Time.current)
        connection.models.find_by(external_id: "bge-m3").update!(deactivated_at: Time.current)

        get llm_models_path

        expect(response.body).to include("huggingface.co/blog/getting-started-with-embeddings")
        expect(response.body).not_to include("set its type to Embedding model")
      end

      # Otherwise a save would silently blank a working configuration.
      it "keeps the stored embedding default listed, flagged, once it is ruled out" do
        connection = create(:llm_connection, :with_models, base_url:)
        connection.update_column(:default_embedding_model_id, connection.models.find_by(external_id: "qwen3.6-27b").id)

        get llm_models_path

        expect(offered_default_models(:default_embedding_model_id)).to include("qwen3.6-27b")
        expect(response.body).to include("not known to create embeddings")
      end

      it "keeps a stored default listed once its model is switched off" do
        connection = create(:llm_connection, :with_models, base_url:)
        chat_model = connection.models.find_by(external_id: "qwen3.6-27b")
        connection.update!(default_chat_model: chat_model)
        chat_model.update!(deactivated_at: Time.current)

        get llm_models_path

        expect(offered_default_models).to include("qwen3.6-27b")
      end

      it "sends the administrator to the settings while the features are off",
         with_settings: { llm_features_enabled: false } do
        create(:llm_connection, :with_models, base_url:)

        get llm_models_path

        expect(response).to redirect_to(llm_connection_path)
        expect(flash[:notice]).to eq(I18n.t("admin.llm_connections.disabled_notice"))
      end

      it "sends the administrator to the settings while no connection is stored" do
        get llm_models_path

        expect(response).to redirect_to(llm_connection_path)
      end
    end
  end

  describe "POST /admin/llm_models/refresh" do
    let!(:connection) { create(:llm_connection, base_url:) }

    before { login_as admin }

    it "fetches the model list again" do
      mock_llm_models_response(base_url)

      post refresh_llm_models_path

      expect(response).to redirect_to(llm_models_path)
      expect(connection.reload.available_model_ids).to contain_exactly("qwen3.6-27b", "bge-m3")
      expect(flash[:notice]).to eq("The model list has been refreshed.")
    end

    it "says so when the server cannot be reached" do
      mock_llm_models_response(base_url, timeout: true)

      post refresh_llm_models_path

      expect(response).to redirect_to(llm_models_path)
      expect(flash[:error]).to be_present
    end
  end

  describe "paginating the model list" do
    let!(:connection) { create(:llm_connection, base_url: "https://example.com/v1") }

    before do
      login_as admin
      # A gateway can report hundreds; OpenRouter returns 341.
      25.times { |n| create(:llm_model, llm_connection: connection, external_id: format("model-%03d", n)) }
    end

    def rendered_rows(body) = body.scan("llm-model--toggle-").size

    it "shows one page of rows at a time rather than every model" do
      get llm_models_path, params: { per_page: 20 }

      expect(rendered_rows(response.body)).to eq(20)
      expect(response.body).to include("op-pagination")
    end

    it "serves the remainder on the next page" do
      get llm_models_path, params: { per_page: 20, page: 2 }

      expect(rendered_rows(response.body)).to eq(5)
    end
  end

  describe "filtering the model list" do
    let!(:connection) { create(:llm_connection, base_url: "https://example.com/v1") }
    let(:filters) { [{ name: { operator: "~", values: ["bge"] } }].to_json }

    before do
      login_as admin
      create(:llm_model, llm_connection: connection, external_id: "qwen3.6-27b")
      create(:llm_model, llm_connection: connection, external_id: "bge-m3")
      create(:llm_model, llm_connection: connection, external_id: "e5-large", display_name: "BGE compatible")
    end

    def rendered_rows(body) = body.scan("llm-model--toggle-").size

    it "narrows the table to matching models" do
      get search_llm_models_path, params: { filters: }

      expect(response).to have_http_status(:ok)
      # The identifier and the friendly name both match, since either is what
      # somebody would type.
      expect(rendered_rows(response.body)).to eq(2)
      expect(response.body).to include("bge-m3")
    end

    it "answers with a turbo stream so only the table is replaced" do
      get search_llm_models_path, params: { filters: }

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end

    it "applies the filter to the full page too, so a shared link works" do
      get llm_models_path, params: { filters: }

      expect(rendered_rows(response.body)).to eq(2)
    end

    it "shows everything without a filter" do
      get llm_models_path

      expect(rendered_rows(response.body)).to eq(3)
    end
  end

  # Manual entry exists for servers that route /v1/chat/completions but expose no
  # model list -- OpenProject's own hosted gateway does exactly that today.
  describe "models entered by hand" do
    let!(:connection) { create(:llm_connection, base_url:) }

    before { login_as admin }

    describe "POST /admin/llm_models" do
      it "accepts everything the edit screen accepts" do
        post llm_models_path, params: { llm_model: { external_id: "bge-m3",
                                                     display_name: "BGE M3",
                                                     admin_context_window: "8192",
                                                     model_type: "embedding" } }

        llm_model = connection.models.find_by(external_id: "bge-m3")
        expect(llm_model.display_name).to eq("BGE M3")
        expect(llm_model.context_window).to eq(8192)

        verdicts = connection.capability_verdicts.for_model("bge-m3").pluck(:capability, :state, :source)
        expect(verdicts).to include(["embeddings", "supported", "admin"])
      end

      it "adds a model an administrator names" do
        post llm_models_path, params: { llm_model: { external_id: "qwen3.6-35b-a3b" } }

        expect(response).to redirect_to(llm_models_path)
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

        post refresh_llm_models_path

        expect(connection.models.find_by(external_id: "hand-typed")).to be_active
        expect(connection.models.find_by(external_id: "was-discovered")).not_to be_active
        expect(connection.available_model_ids).to include("hand-typed", "qwen3.6-27b")
      end

      # The server reports an id and nothing else, so a refresh that adopts the
      # card verbatim would throw away the name an administrator gave the model.
      it "keeps an edited display name across a refresh that reports the model" do
        llm_model = create(:llm_model, :manual, llm_connection: connection, external_id: "qwen3.6-27b")
        patch llm_model_path(llm_model), params: { llm_model: { display_name: "Our house model" } }
        mock_llm_models_response(base_url)

        post refresh_llm_models_path

        expect(llm_model.reload.display_name).to eq("Our house model")
      end
    end

    describe "PATCH /admin/llm_models/:id" do
      let!(:llm_model) { create(:llm_model, :manual, llm_connection: connection, external_id: "hand-typed") }

      it "stores capabilities an administrator asserts" do
        patch llm_model_path(llm_model),
              params: { llm_model: { display_name: "Hand typed",
                                     model_type: "chat",
                                     capability_vision: "unsupported" } }

        expect(response).to redirect_to(llm_models_path)
        expect(llm_model.reload.display_name).to eq("Hand typed")

        verdicts = connection.capability_verdicts.for_model("hand-typed").pluck(:capability, :state, :source)
        expect(verdicts).to include(["vision", "unsupported", "admin"])
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

      it "makes an asserted type satisfy a feature that requires it" do
        patch llm_model_path(llm_model), params: { llm_model: { model_type: "embedding" } }

        patch llm_feature_binding_path("semantic_search"),
              params: { llm_feature_binding: { model_id: "hand-typed" } }

        expect(connection.feature_bindings.find_by(feature_key: "semantic_search").model_id).to eq("hand-typed")
      end

      # Clearing an assertion records nothing rather than recording ignorance as
      # fact, so detection can still fill it in later.
      it "clears an assertion when set back to unspecified" do
        patch llm_model_path(llm_model), params: { llm_model: { capability_vision: "supported" } }
        patch llm_model_path(llm_model), params: { llm_model: { capability_vision: "" } }

        expect(connection.capability_verdicts.for_model("hand-typed").for_capability(:vision)).to be_empty
      end

      # An administrator looked at this deployment; a published registry did not.
      it "is not overwritten by registry enrichment" do
        patch llm_model_path(llm_model), params: { llm_model: { model_type: "embedding" } }

        LlmConnections::EnrichCapabilitiesService.new(connection).call

        verdict = connection.capability_verdicts.find_by(model_id: "hand-typed", capability: "embeddings")
        expect(verdict.source).to eq("admin")
        expect(verdict.state).to eq("supported")
      end
    end

    describe "choosing the model type" do
      let!(:llm_model) { create(:llm_model, :manual, llm_connection: connection, external_id: "hand-typed") }

      it "offers the chat capabilities to a chat model" do
        get edit_llm_model_path(llm_model)

        expect(page).to have_css("[data-test-selector='llm-model--chat-capabilities']", visible: :visible)
      end

      # An embedding model answers no chat request, so tool calling and the rest
      # cannot apply to it.
      it "hides the chat capabilities from an embedding model" do
        patch llm_model_path(llm_model), params: { llm_model: { model_type: "embedding" } }

        get edit_llm_model_path(llm_model)

        expect(page).to have_css("[data-test-selector='llm-model--chat-capabilities']", visible: :hidden)
        expect(page).to have_no_css("[data-test-selector='llm-model--chat-capabilities']", visible: :visible)
      end

      it "drops chat assertions when a model becomes an embedding model" do
        patch llm_model_path(llm_model), params: { llm_model: { model_type: "chat", capability_vision: "supported" } }

        patch llm_model_path(llm_model), params: { llm_model: { model_type: "embedding" } }

        verdicts = connection.capability_verdicts.for_model("hand-typed").pluck(:capability, :state)
        expect(verdicts).to contain_exactly(%w[embeddings supported])
      end

      # Saving a discovered model without touching its type must not turn what a
      # probe or a registry found into the administrator's own assertion.
      it "leaves the stored verdict alone when the type was not changed" do
        discovered = create(:llm_model, llm_connection: connection, external_id: "from-server")
        connection.capability_verdicts.create!(model_id: "from-server", capability: "embeddings",
                                               state: "unsupported", source: "probe", checked_at: Time.current)

        patch llm_model_path(discovered), params: { llm_model: { model_type: "chat", display_name: "From server" } }

        verdict = connection.capability_verdicts.find_by(model_id: "from-server", capability: "embeddings")
        expect(verdict.source).to eq("probe")
      end

      it "re-renders the form when an asserted state is not a state" do
        patch llm_model_path(llm_model), params: { llm_model: { model_type: "chat", capability_vision: "maybe" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(connection.capability_verdicts.for_model("hand-typed")).to be_empty
      end
    end

    describe "the model type shown in the list" do
      it "reads as an embedding model once the type says so" do
        llm_model = create(:llm_model, :manual, llm_connection: connection, external_id: "bge-m3")
        patch llm_model_path(llm_model), params: { llm_model: { model_type: "embedding" } }

        get llm_models_path

        expect(response.body).to include("Embedding")
      end

      it "reads as a chat model when the type says so" do
        llm_model = create(:llm_model, :manual, llm_connection: connection, external_id: "qwen")
        patch llm_model_path(llm_model), params: { llm_model: { model_type: "chat" } }

        get llm_models_path

        expect(response.body).to include("Chat")
      end
    end

    describe "GET /admin/llm_models/new" do
      it "renders the add-model form" do
        get new_llm_model_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Model name")
      end

      # Not every administrator knows what an embedding model is.
      it "points at the documentation about model types" do
        get new_llm_model_path

        expect(page).to have_link("Read more", href: %r{huggingface\.co/blog/getting-started-with-embeddings})
      end

      it "re-renders with the error inline when the name is taken" do
        create(:llm_model, llm_connection: connection, external_id: "already-there")

        post llm_models_path, params: { llm_model: { external_id: "already-there" } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(connection.models.where(external_id: "already-there").count).to eq(1)
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

        expect(response).to redirect_to(llm_models_path)
        expect(LlmModel.where(id: llm_model.id)).to be_empty
      end

      # cascade_rename! keeps the defaults pointing at the model; deleting one has
      # to let go of it, or the connection keeps a default no model answers to.
      it "lets go of a connection default that named the deleted model" do
        llm_model = create(:llm_model, :manual, llm_connection: connection, external_id: "hand-typed")
        connection.update!(default_chat_model: llm_model)

        delete llm_model_path(llm_model)

        expect(connection.reload.default_chat_model).to be_nil
      end

      # Discovered models are the server's to add and remove, not the administrator's.
      it "refuses to remove a discovered model" do
        llm_model = create(:llm_model, llm_connection: connection, external_id: "from-server")

        delete llm_model_path(llm_model)

        expect(response).to have_http_status(:not_found)
        expect(LlmModel.where(id: llm_model.id)).to exist
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

    describe "renaming a manually added model" do
      let!(:llm_model) do
        create(:llm_model, :manual, llm_connection: connection, external_id: "qwen/qwen3.6-35b-a3b")
      end

      before do
        connection.update!(default_chat_model: llm_model)
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
        expect(connection.reload.default_chat_model).to eq(llm_model)
        expect(connection.feature_bindings.first.model_id).to eq("qwen/qwen3.6-35b-a3b:bf16")
        expect(connection.capability_verdicts.first.model_id).to eq("qwen/qwen3.6-35b-a3b:bf16")
      end

      it "keeps the feature resolving afterwards", with_flag: { llm_connection: true } do
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

      # The blank option names what applies while nothing is asserted here, so
      # that choosing it is understood as "follow the server" rather than as an
      # assertion of ignorance.
      it "offers to inherit the value the server reports" do
        connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "function_calling",
                                               state: "supported", source: "metadata", checked_at: Time.current)

        get edit_llm_model_path(llm_model)

        expect(response.body).to include("Inherit from server (supported)")
      end

      it "says the server has not verified it when nothing is known" do
        get edit_llm_model_path(llm_model)

        expect(response.body).to include("Inherit from server (not verified)")
      end

      # An administrator's own assertion is loaded into the field, so the blank
      # option must not claim it as inherited.
      it "does not present an administrator's own assertion as inherited" do
        connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "function_calling",
                                               state: "supported", source: "admin", checked_at: Time.current)

        get edit_llm_model_path(llm_model)

        expect(response.body).to include("Inherit from server (not verified)")
        expect(response.body).not_to include("Inherit from server (supported)")
      end
    end
  end

  describe "PATCH /admin/llm_models/defaults" do
    let!(:connection) { create(:llm_connection, :with_models, base_url:) }
    let(:chat_model) { connection.models.find_by(external_id: "qwen3.6-27b") }

    before { login_as admin }

    it "stores the default chat model without contacting the server" do
      patch defaults_llm_models_path, params: { llm_connection: { default_chat_model_id: chat_model.id } }

      expect(response).to redirect_to(llm_models_path)
      expect(connection.reload.default_chat_model).to eq(chat_model)
      expect(flash[:notice]).to eq("The default models have been saved.")
      expect(a_request(:get, "#{base_url}/models")).not_to have_been_made
    end

    it "refuses a model the server does not offer" do
      patch defaults_llm_models_path,
            params: { llm_connection: { default_chat_model_id: LlmModel.maximum(:id).to_i + 1 } }

      expect(connection.reload.default_chat_model_id).to be_nil
      expect(flash[:error]).to be_present
    end

    it "stores the default embedding model" do
      connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                             state: "supported", source: "probe", checked_at: Time.current)

      patch defaults_llm_models_path,
            params: { llm_connection: { default_embedding_model_id: connection.models.find_by(external_id: "bge-m3").id } }

      expect(connection.reload.default_embedding_model.external_id).to eq("bge-m3")
    end

    it "refuses a model the server has ruled out" do
      connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "embeddings",
                                             state: "unsupported", source: "probe", checked_at: Time.current)

      patch defaults_llm_models_path,
            params: { llm_connection: { default_embedding_model_id: connection.models.find_by(external_id: "qwen3.6-27b").id } }

      expect(connection.reload.default_embedding_model_id).to be_nil
      expect(flash[:error]).to be_present
    end

    # Nothing has probed the row: refusing here would break provisioning from the
    # environment, where the same configuration passes on an empty catalogue.
    it "accepts a model nothing has ruled out" do
      patch defaults_llm_models_path,
            params: { llm_connection: { default_embedding_model_id: connection.models.find_by(external_id: "qwen3.6-27b").id } }

      expect(connection.reload.default_embedding_model.external_id).to eq("qwen3.6-27b")
    end

    it "leaves the server settings alone" do
      patch defaults_llm_models_path,
            params: { llm_connection: { default_chat_model_id: chat_model.id, base_url: "https://elsewhere.test/v1" } }

      expect(connection.reload.base_url).to eq(base_url)
    end

    it "refuses a default the environment owns" do
      allow(Setting).to receive(:llm_connection).and_return({ "base_url" => base_url })

      patch defaults_llm_models_path,
            params: { llm_connection: { default_chat_model_id: connection.models.find_by(external_id: "qwen3.6-27b").id } }

      expect(connection.reload.default_chat_model_id).to be_nil
      expect(flash[:error]).to be_present
    end

    it "is refused to a non-admin" do
      login_as create(:user)

      patch defaults_llm_models_path, params: { llm_connection: { default_chat_model_id: chat_model.id } }

      expect(connection.reload.default_chat_model_id).to be_nil
    end
  end

  describe "POST /admin/llm_models/:id/toggle" do
    let!(:connection) { create(:llm_connection, base_url:) }
    let!(:llm_model) { create(:llm_model, llm_connection: connection, external_id: "qwen3.6-27b") }

    before { login_as admin }

    it "hides the model from the pickers and puts it back" do
      post toggle_llm_model_path(llm_model)

      expect(response).to have_http_status(:ok)
      expect(llm_model.reload).to be_deactivated
      expect(connection.selectable_model_ids).not_to include("qwen3.6-27b")

      post toggle_llm_model_path(llm_model)

      expect(llm_model.reload).not_to be_deactivated
      expect(connection.selectable_model_ids).to include("qwen3.6-27b")
    end

    it "offers the default pickers again without the model it just switched off" do
      post toggle_llm_model_path(llm_model)

      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('target="llm-connections-default-models-component"')
      expect(offered_default_models(markup: streamed_markup)).not_to include("qwen3.6-27b")
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

    it "leaves the source of a hidden model answering where it came from" do
      create(:llm_model, :manual, :deactivated, llm_connection: connection, external_id: "by-hand")

      get llm_models_path

      expect(response.body).to include("Added manually by an administrator")
      expect(response.body).not_to include("Hidden")
    end
  end
end
