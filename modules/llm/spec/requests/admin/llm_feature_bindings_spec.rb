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

RSpec.describe "Admin AI feature configuration", :llm_server_helpers, :skip_csrf, :webmock,
               type: :rails_request, with_flag: { llm_connection: true, semantic_search: true },
               with_settings: { llm_features_enabled: true } do
  let(:admin) { create(:admin) }
  let(:base_url) { "https://example.com/v1" }

  # The picker is an autocompleter, so its options are serialized into the
  # element rather than rendered as markup.
  def offered_models(feature_key)
    items = page.find("form[action='#{llm_feature_binding_path(feature_key)}'] opce-autocompleter")["data-items"]

    JSON.parse(items).pluck("id").compact_blank
  end

  describe "with the feature flag off", with_flag: { llm_connection: false } do
    let!(:connection) { create(:llm_connection, :with_models, base_url:) }

    before { login_as admin }

    it "does not expose the endpoints" do
      get llm_feature_bindings_path
      expect(response).to have_http_status(:not_found)

      patch llm_feature_binding_path("description_assistant"),
            params: { llm_feature_binding: { model_id: "qwen3.6-27b" } }
      expect(response).to have_http_status(:not_found)
      expect(connection.feature_bindings).to be_empty
    end
  end

  describe "as a non-admin" do
    let!(:connection) { create(:llm_connection, :with_models, base_url:) }

    before { login_as create(:user) }

    it "refuses the page" do
      get llm_feature_bindings_path

      expect(response).to have_http_status(:forbidden)
    end

    it "refuses to store a model" do
      patch llm_feature_binding_path("description_assistant"),
            params: { llm_feature_binding: { model_id: "qwen3.6-27b" } }

      expect(response).to have_http_status(:forbidden)
      expect(connection.feature_bindings).to be_empty
    end
  end

  describe "GET /admin/llm_feature_bindings" do
    before { login_as admin }

    it "sends the administrator to the settings while no connection is stored" do
      get llm_feature_bindings_path

      expect(response).to redirect_to(llm_connection_path)
    end

    it "sends the administrator to the settings while the features are off",
       with_settings: { llm_features_enabled: false } do
      create(:llm_connection, :with_models, base_url:)

      get llm_feature_bindings_path

      expect(response).to redirect_to(llm_connection_path)
      expect(flash[:notice]).to eq(I18n.t("admin.llm_connections.disabled_notice"))
    end

    context "with a configured connection" do
      let!(:connection) { create(:llm_connection, :with_models, base_url:) }

      it "lists every registered feature" do
        get llm_feature_bindings_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Feature configuration")
        expect(response.body).to include("Description assistant")
        expect(response.body).to include("Semantic search")
      end

      # Semantic search is registered but not built, so it carries a flag of its
      # own. Registration alone must not put it on the tab.
      it "leaves out a feature whose own flag is off",
         with_flag: { llm_connection: true, semantic_search: false } do
        get llm_feature_bindings_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Description assistant")
        expect(response.body).not_to include("Semantic search")
      end

      it "offers the tabs of the LLM settings page" do
        get llm_feature_bindings_path

        expect(page).to have_css("[data-test-selector='llm-settings--tabs'] a[href='#{llm_connection_path}']")
        expect(page).to have_css("[data-test-selector='llm-settings--tabs'] a[href='#{llm_models_path}']")
        expect(page).to have_css("[data-test-selector='llm-settings--tabs'] a[href='#{llm_feature_bindings_path}']")
      end

      it "points at the page where the default models are chosen" do
        get llm_feature_bindings_path

        expect(response.body).to include("use the default models set on the")
        expect(response.body).to include(llm_models_path)
      end

      it "names the default model a feature inherits" do
        default = connection.models.find_by!(external_id: "qwen3.6-27b")
        default.update!(display_name: "Qwen 3.6")
        connection.update!(default_chat_model: default)

        get llm_feature_bindings_path

        expect(response.body).to include("Use the default (Qwen 3.6)")
      end

      context "without pgvector" do
        let(:warning) { "[data-test-selector='llm-feature-bindings--pgvector-unavailable']" }

        before { allow(OpenProject::Llm::Pgvector).to receive(:available?).and_return(false) }

        it "warns that semantic search is unavailable" do
          get llm_feature_bindings_path

          expect(page).to have_css(warning)
          expect(page).to have_link(href: OpenProject::Llm::Pgvector::DOCS_URL)
        end

        it "does not warn when semantic search is switched off",
           with_flag: { llm_connection: true, semantic_search: false } do
          get llm_feature_bindings_path

          expect(response.body).to include("Feature configuration")
          expect(page).to have_no_css(warning)
        end
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

    it "refuses a model the server does not offer" do
      patch llm_feature_binding_path("description_assistant"),
            params: { llm_feature_binding: { model_id: "no-such-model" } }

      expect(connection.feature_bindings.find_by(feature_key: "description_assistant")).to be_nil
      expect(flash[:error]).to include("is not offered by the configured LLM server")
    end

    it "treats a blank choice as inheriting the default" do
      create(:llm_feature_binding, llm_connection: connection, feature_key: "description_assistant", model_id: "qwen3.6-27b")

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

    context "when the probe rules out a capability the feature requires" do
      let(:feature_key) { :spec_only_vision_feature }
      let(:verdict) do
        create(:llm_capability_verdict, llm_connection: connection, model_id: "qwen3.6-27b", capability: "vision",
                                        state: "unsupported", source: "probe")
      end

      before do
        OpenProject::Llm::Features.register(feature_key, kind: :chat, requires: %i[vision],
                                                         i18n_scope: "llm.features.description_assistant")
        allow(LlmConnections::DetectCapabilitiesService)
          .to receive(:new)
          .and_return(instance_double(LlmConnections::DetectCapabilitiesService,
                                      detect: ServiceResult.success(result: verdict)))
      end

      after { OpenProject::Llm::Features.all.delete(feature_key) }

      it "says that models were left out of the picker" do
        get llm_feature_bindings_path

        expect(response.body).to include(I18n.t("admin.llm_feature_bindings.form.model_caption_ruled_out"))
      end

      it "says nothing of the kind once no model is ruled out" do
        verdict.destroy!

        get llm_feature_bindings_path

        expect(response.body).not_to include(I18n.t("admin.llm_feature_bindings.form.model_caption_ruled_out"))
      end

      it "names the capability the verdict is about" do
        patch llm_feature_binding_path(feature_key), params: { llm_feature_binding: { model_id: "qwen3.6-27b" } }

        expect(flash[:error]).to include("does not support Vision")
      end
    end

    it "refuses a request that carries no binding" do
      create(:llm_feature_binding, llm_connection: connection, feature_key: "description_assistant", model_id: "qwen3.6-27b")

      patch llm_feature_binding_path("description_assistant")

      expect(response).to have_http_status(:bad_request)
      expect(connection.feature_bindings.find_by(feature_key: "description_assistant").model_id)
        .to eq("qwen3.6-27b")
    end

    it "404s for a feature that is not registered" do
      patch llm_feature_binding_path("no_such_feature"), params: { llm_feature_binding: { model_id: "x" } }

      expect(response).to have_http_status(:not_found)
    end
  end
end
