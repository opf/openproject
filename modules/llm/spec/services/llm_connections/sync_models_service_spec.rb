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

RSpec.describe LlmConnections::SyncModelsService, :llm_server_helpers, :webmock do
  subject(:service) { described_class.new(connection) }

  let(:base_url) { "https://example.com/v1" }
  let(:connection) { create(:llm_connection, :with_models, base_url:, api_key: "sk-test") }

  before { mock_llm_models_response(base_url) }

  describe "switching to a different deployment" do
    before do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "qwen3.6-27b", capability: "embeddings",
                                      state: "supported", source: "admin")
      create(:llm_capability_verdict, llm_connection: connection, model_id: "qwen3.6-27b", capability: "vision",
                                      state: "unsupported", source: "metadata")
      connection.update_columns(base_url: "https://elsewhere.example/v1",
                                connection_fingerprint: "the-previous-deployment")
    end

    it "invalidates the old models and verdicts even when the new server offers no list" do
      mock_llm_models_response("https://elsewhere.example/v1", response_code: 404)

      result = service.call

      expect(result).to be_failure
      expect(connection.capability_verdicts.pluck(:capability, :source)).to eq([%w[embeddings admin]])
      expect(connection.models.active).to be_empty
    end

    it "keeps warning about a stale list when the new server refuses it" do
      mock_llm_models_response("https://elsewhere.example/v1", response_code: 404)

      expect(service.call).to be_failure
      expect(connection.reload).to be_models_stale
    end

    it "keeps administrator assertions and re-fetches what the new server reports" do
      mock_llm_models_response("https://elsewhere.example/v1")

      described_class.new(connection).call

      expect(connection.capability_verdicts.where(source: "admin").pluck(:capability)).to eq(["embeddings"])
      expect(connection.models.active.pluck(:external_id)).to contain_exactly("qwen3.6-27b", "bge-m3")
    end

    # Switched off was not enough: the rows stayed in the list, and a list of a
    # server this connection no longer talks to is a leftover, not a catalogue.
    it "deletes the models the previous server offered" do
      mock_llm_models_response("https://elsewhere.example/v1", response_code: 405)

      expect { service.call }.to change { connection.models.discovered.count }.to(0)
    end

    it "keeps a model an administrator entered by hand" do
      create(:llm_model, :manual, llm_connection: connection, external_id: "hand-typed")
      mock_llm_models_response("https://elsewhere.example/v1", response_code: 405)

      service.call

      expect(connection.models.manual.pluck(:external_id)).to eq(["hand-typed"])
    end

    it "lets go of a feature bound to a model the previous server offered" do
      create(:llm_feature_binding, llm_connection: connection, feature_key: "description_assistant", model_id: "qwen3.6-27b")
      mock_llm_models_response("https://elsewhere.example/v1", response_code: 405)

      service.call

      expect(connection.feature_bindings).to be_empty
    end

    it "keeps a locked binding, which records what an existing index was written with" do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3", capability: "embeddings",
                                      state: "supported", source: "probe")
      binding = create(:llm_feature_binding, llm_connection: connection, feature_key: "semantic_search", model_id: "bge-m3",
                                             dimensions: 1024, locked_at: Time.current)
      mock_llm_models_response("https://elsewhere.example/v1", response_code: 405)

      service.call

      expect(binding.reload).to have_attributes(model_id: "bge-m3", dimensions: 1024)
      expect(binding).to be_locked
    end

    it "leaves a kept binding dangling when the new server offers a model of the same name" do
      binding = create(:llm_feature_binding, llm_connection: connection, feature_key: "description_assistant",
                                             model_id: "qwen3.6-27b")
      binding.update_columns(locked_at: Time.current, locked_deployment_fingerprint: connection.connection_fingerprint)
      mock_llm_models_response("https://elsewhere.example/v1")

      service.call

      expect(connection.reload.available_model_ids).to include("qwen3.6-27b")
      expect(binding.reload).to be_dangling
    end

    # on_delete: :nullify on the two default_*_model_id foreign keys.
    it "lets go of a connection default that named a model the previous server offered" do
      connection.update!(default_chat_model: connection.models.find_by(external_id: "qwen3.6-27b"))
      mock_llm_models_response("https://elsewhere.example/v1", response_code: 405)

      service.call

      expect(connection.reload.default_chat_model_id).to be_nil
    end
  end

  describe "rotating only the API key" do
    let(:chat_model) { connection.models.find_by!(external_id: "qwen3.6-27b") }
    let(:embedding_model) { connection.models.find_by!(external_id: "bge-m3") }

    before do
      connection.update!(connection_fingerprint: connection.settings_fingerprint,
                         default_chat_model: chat_model,
                         default_embedding_model: embedding_model)
      connection.update!(api_key: "sk-rotated")
    end

    it "keeps the discovered models" do
      expect { service.call }.not_to change { connection.models.discovered.order(:id).pluck(:id) }
    end

    it "keeps the default models" do
      service.call

      connection.reload
      expect(connection.default_chat_model_id).to eq(chat_model.id)
      expect(connection.default_embedding_model_id).to eq(embedding_model.id)
    end
  end

  describe "refreshing the same deployment" do
    before { service.call }

    it "keeps an administrator's context window override across refreshes" do
      llm_model = connection.models.find_by(external_id: "qwen3.6-27b")
      llm_model.update!(raw_metadata: llm_model.raw_metadata.merge("admin_context_window" => 4096))

      described_class.new(connection).call

      expect(llm_model.reload.context_window).to eq(4096)
    end

    it "keeps an administrator's display name when the server reports none" do
      llm_model = connection.models.find_by(external_id: "qwen3.6-27b")
      llm_model.update!(display_name: "The house model")

      described_class.new(connection).call

      expect(llm_model.reload.display_name).to eq("The house model")
    end

    # What the server calls a model is metadata; what an administrator calls it is
    # the column. A refresh may update the first and never the second, which the
    # registry-backed adapters used to break by naming every card.
    it "keeps the administrator's name and files the reported one beside it" do
      llm_model = connection.models.find_by(external_id: "qwen3.6-27b")
      llm_model.update!(display_name: "The house model")
      allow(Llm::Adapters).to receive(:for).and_return(
        instance_double(Llm::Adapters::RegistryBacked,
                        models: [{ id: "qwen3.6-27b", raw: { "name" => "Qwen 3.6 27B" } }],
                        server_flavour: "anthropic")
      )

      described_class.new(connection).call

      expect(llm_model.reload.display_name).to eq("The house model")
      expect(llm_model.name).to eq("The house model")
      expect(llm_model.raw_metadata["name"]).to eq("Qwen 3.6 27B")
    end

    # The everyday case: the same server still answers, one model is simply gone.
    it "withdraws a model the server stopped reporting and drops its verdict" do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3", capability: "embeddings",
                                      state: "supported", source: "probe")
      create(:llm_capability_verdict, llm_connection: connection, model_id: "qwen3.6-27b", capability: "vision",
                                      state: "supported", source: "probe")
      mock_llm_models_response(base_url, models: [{ id: "qwen3.6-27b", object: "model" }])

      described_class.new(connection).call

      expect(connection.models.find_by(external_id: "bge-m3")).to be_withdrawn
      expect(connection.models.find_by(external_id: "qwen3.6-27b")).to be_active
      expect(connection.capability_verdicts.pluck(:model_id)).to eq(["qwen3.6-27b"])
    end

    it "drops every non-admin verdict when the catalogue comes back empty" do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "qwen3.6-27b", capability: "embeddings",
                                      state: "supported", source: "probe")
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3", capability: "embeddings",
                                      state: "supported", source: "admin")
      mock_llm_models_response(base_url, body: { object: "list", data: [] }.to_json)

      # A fresh instance, as every caller builds one: the adapter memoises the
      # fetched list within a run.
      described_class.new(connection).call

      expect(connection.capability_verdicts.pluck(:source)).to eq(["admin"])
    end

    it "refuses a card that claims an administrator's context window" do
      mock_llm_models_response(base_url,
                               models: [{ id: "qwen3.6-27b", admin_context_window: 999, max_model_len: 4096 }])

      described_class.new(connection).call

      llm_model = connection.models.find_by(external_id: "qwen3.6-27b")
      expect(llm_model.raw_metadata).not_to have_key("admin_context_window")
      expect(llm_model.context_window_source).to eq(:server)
    end

    it "skips a card whose id is too long to store and keeps the rest" do
      longest = "x" * LlmModel::MAX_EXTERNAL_ID_LENGTH
      oversized = "#{longest}x"
      mock_llm_models_response(base_url, models: [{ id: oversized, object: "model" },
                                                  { id: longest, object: "model" },
                                                  { id: "qwen3.6-27b", object: "model" },
                                                  { id: "bge-m3", object: "model" }])

      expect(described_class.new(connection).call).to be_success
      expect(connection.models.active.pluck(:external_id)).to contain_exactly(longest, "qwen3.6-27b", "bge-m3")
      expect(connection.models.find_by(external_id: oversized)).to be_nil
    end

    it "fails rather than raising when a card cannot be stored" do
      allow(connection.models).to receive(:find_or_initialize_by).and_raise(ActiveRecord::RecordNotUnique)

      result = described_class.new(connection).call

      expect(result).to be_failure
      expect(result.result).to be_a(ActiveRecord::RecordNotUnique)
    end
  end

  describe "a first sync" do
    let(:connection) { create(:llm_connection, base_url:, api_key: "sk-test", options: { "kept" => "as is" }) }

    it "stores the catalogue and records what it learnt about the deployment" do
      freeze_time do
        service.call

        expect(connection.models.pluck(:external_id)).to contain_exactly("qwen3.6-27b", "bge-m3")
        expect(connection.reload).to have_attributes(last_synced_at: Time.current,
                                                     last_connected_at: Time.current,
                                                     connection_fingerprint: connection.settings_fingerprint)
      end
    end

    it "adds the server flavour to the options without dropping the others" do
      service.call

      expect(connection.reload.options).to eq("kept" => "as is", "server_flavour" => "vllm")
    end

    it "moves the sync and sighting times forward on the next one" do
      travel_to(2.days.ago) { described_class.new(connection).call }

      described_class.new(connection).call

      expect(connection.reload.last_synced_at).to be_within(1.minute).of(Time.current)
      expect(connection.models.pluck(:last_seen_at)).to all(be_within(1.minute).of(Time.current))
    end
  end

  describe "a model the server offers again" do
    before do
      service.call
      connection.models.find_by(external_id: "bge-m3").update!(active: false)
    end

    it "brings back the withdrawn row instead of adding another" do
      expect { described_class.new(connection).call }.not_to change(LlmModel, :count)

      expect(connection.models.find_by(external_id: "bge-m3")).to be_active
    end
  end

  describe "an empty catalogue" do
    let!(:typed) { create(:llm_model, :manual, llm_connection: connection, external_id: "hand-typed") }

    before { mock_llm_models_response(base_url, body: { object: "list", data: [] }.to_json) }

    it "withdraws every discovered model and leaves a manual entry alone" do
      service.call

      expect(connection.models.discovered.active).to be_empty
      expect(typed.reload).to be_active
    end
  end

  describe "a failed fetch" do
    {
      "a timeout" => { timeout: true },
      "a body that is not JSON" => { body: "<html>Gateway</html>" },
      "a 405" => { response_code: 405 },
      "a 501" => { response_code: 501 }
    }.each do |label, response|
      it "leaves the catalogue unchanged on #{label}" do
        mock_llm_models_response(base_url, **response)

        expect { expect(service.call).to be_failure }
          .not_to change { connection.models.reload.map { |model| [model.external_id, model.active, model.last_seen_at] } }
      end
    end
  end

  describe "an enrichment that fails after the catalogue was stored" do
    let(:connection) { create(:llm_connection, base_url:, api_key: "sk-test") }

    before do
      allow(LlmConnections::EnrichCapabilitiesService)
        .to receive(:new).and_raise(ActiveRecord::RecordInvalid)
    end

    it "keeps the stored catalogue and reports the failure" do
      expect(service.call).to be_failure

      expect(connection.models.pluck(:external_id)).to contain_exactly("qwen3.6-27b", "bge-m3")
    end
  end

  describe "a format whose models come from the registry" do
    let(:connection) { create(:llm_connection, base_url:, api_key: "sk-test", api_format: "anthropic") }
    let(:models_request) { mock_llm_models_response(base_url) }

    before do
      models_request
      info = RubyLLM::Model::Info.new(id: "claude-sonnet-4-5", name: "Claude Sonnet 4.5", context_window: 200_000,
                                      provider: "anthropic", modalities: { output: ["text"] })
      allow(RubyLLM.models).to receive(:by_provider).with(:anthropic).and_return([info])
    end

    it "takes the catalogue from the registry without contacting the server" do
      service.call

      expect(models_request).not_to have_been_made
      expect(connection.models.pluck(:external_id, :raw_metadata))
        .to eq([["claude-sonnet-4-5", { "name" => "Claude Sonnet 4.5", "context_window" => 200_000,
                                        "owned_by" => "anthropic" }]])
      expect(connection.reload.server_flavour).to eq(:anthropic)
    end

    it "fails without touching the catalogue when the registry cannot be read" do
      service.call
      allow(RubyLLM.models).to receive(:by_provider).and_raise(RubyLLM::ConfigurationError)

      expect { expect(described_class.new(connection).call).to be_failure }
        .not_to change { connection.models.reload.pluck(:external_id, :active, :last_seen_at) }
      expect(connection.models.pluck(:external_id)).to eq(["claude-sonnet-4-5"])
    end
  end

  describe "a server refusing the model list" do
    it "hands back the error, so a caller can tell whether trying again could help" do
      mock_llm_models_response(base_url, response_code: 404)

      result = service.call

      expect(result).to be_failure
      expect(result.result).to be_a(Llm::Errors::ApiError).and have_attributes(status: 404)
    end
  end

  describe "the capability detection that follows" do
    it "asks for it after a successful sync, whichever caller asked for the list" do
      expect { service.call }.to have_enqueued_job(Llm::DetectCapabilitiesJob)
    end

    it "asks for nothing when the server does not answer with a list" do
      mock_llm_models_response(base_url, response_code: 404)

      expect { service.call }.not_to have_enqueued_job(Llm::DetectCapabilitiesJob)
    end
  end

  describe "naming a model and sizing its context window" do
    let(:connection) { create(:llm_connection, base_url:, api_key: "sk-test") }

    it "reads both off a card that names them in the gateway's own vocabulary" do
      mock_llm_models_response(base_url,
                               models: [{ id: "openai/gpt-4o", name: "OpenAI: GPT-4o", context_length: 128_000 }])

      service.call

      llm_model = connection.models.find_by(external_id: "openai/gpt-4o")
      expect(llm_model.name).to eq("OpenAI: GPT-4o")
      expect(llm_model.context_window).to eq(128_000)
    end

    it "takes the window from max_model_len when the card also names a context_length" do
      mock_llm_models_response(base_url,
                               models: [{ id: "qwen3.6-27b", context_length: 262_144, max_model_len: 32_768 }])

      service.call

      llm_model = connection.models.find_by(external_id: "qwen3.6-27b")
      expect(llm_model.context_window).to eq(32_768)
      expect(llm_model.context_window_source).to eq(:server)
    end

    it "falls back to the registry for a server that lists bare ids" do
      mock_llm_models_response(base_url, models: [{ id: "gpt-4o", object: "model" }])

      service.call

      llm_model = connection.models.find_by(external_id: "gpt-4o")
      expect(llm_model.name).to eq("GPT-4o")
      expect(llm_model.context_window).to eq(128_000)
    end

    it "keeps the published window under an administrator's override" do
      mock_llm_models_response(base_url, models: [{ id: "gpt-4o", object: "model" }])
      service.call
      llm_model = connection.models.find_by(external_id: "gpt-4o")
      llm_model.update!(admin_context_window: 8_000)

      described_class.new(connection).call

      expect(llm_model.reload.context_window).to eq(8_000)

      llm_model.update!(admin_context_window: nil)

      expect(llm_model.reload.context_window).to eq(128_000)
    end

    it "keeps an administrator's display name over the one the registry publishes" do
      mock_llm_models_response(base_url, models: [{ id: "gpt-4o", object: "model" }])
      service.call
      connection.models.find_by(external_id: "gpt-4o").update!(display_name: "The house model")

      described_class.new(connection).call

      expect(connection.models.find_by(external_id: "gpt-4o").display_name).to eq("The house model")
    end
  end

  describe "a gateway that serves its embedding models separately" do
    let(:base_url) { "https://openrouter.ai/api/v1" }
    let(:connection) { create(:llm_connection, base_url:, api_format: "openrouter", api_key: "sk-test") }

    before { mock_llm_embedding_models_response(base_url) }

    it "stores the models the unfiltered catalogue leaves out" do
      service.call

      expect(connection.models.active.pluck(:external_id))
        .to contain_exactly("qwen3.6-27b", "bge-m3", "voyageai/voyage-4")
    end

    it "keeps the embedding models when the catalogue outgrows the cap" do
      stub_const("#{described_class}::MAX_CARDS", 2)

      service.call

      expect(connection.models.active.pluck(:external_id)).to include("voyageai/voyage-4")
    end

    it "types a model the card declares an embedding one without spending a probe" do
      service.call

      llm_model = connection.models.find_by(external_id: "voyageai/voyage-4")
      verdict = connection.capability_verdicts.find_by(model_id: "voyageai/voyage-4", capability: "embeddings")

      expect(llm_model).to be_embedding
      expect(verdict.source).to eq("metadata")
    end
  end
end
