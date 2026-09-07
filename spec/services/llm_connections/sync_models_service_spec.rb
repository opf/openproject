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

RSpec.describe LlmConnections::SyncModelsService, :llm_server_helpers, :webmock do
  subject(:service) { described_class.new(connection) }

  let(:base_url) { "https://example.com/v1" }
  let(:connection) { create(:llm_connection, :with_models, base_url:, api_key: "sk-test") }

  before { mock_llm_models_response(base_url) }

  describe "switching to a different deployment" do
    before do
      connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "embeddings",
                                             state: "supported", source: "admin", checked_at: Time.current)
      connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "vision",
                                             state: "unsupported", source: "metadata", checked_at: Time.current)
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

    it "keeps administrator assertions and re-activates what the new server reports" do
      mock_llm_models_response("https://elsewhere.example/v1")

      described_class.new(connection).call

      expect(connection.capability_verdicts.where(source: "admin").pluck(:capability)).to eq(["embeddings"])
      expect(connection.models.active.pluck(:external_id)).to contain_exactly("qwen3.6-27b", "bge-m3")
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

    # Only the registry-backed adapters report a name; a server speaking the
    # OpenAI API lists ids and nothing else.
    it "adopts the display name the adapter reports" do
      llm_model = connection.models.find_by(external_id: "qwen3.6-27b")
      llm_model.update!(display_name: "The house model")
      allow(Llm::Adapters).to receive(:for).and_return(
        instance_double(Llm::Adapters::RegistryBacked,
                        models: [{ id: "qwen3.6-27b", display_name: "Qwen 3.6 27B", raw: {} }],
                        server_flavour: "anthropic")
      )

      described_class.new(connection).call

      expect(llm_model.reload.display_name).to eq("Qwen 3.6 27B")
    end

    it "drops every non-admin verdict when the catalogue comes back empty" do
      connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "embeddings",
                                             state: "supported", source: "probe", checked_at: Time.current)
      connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                             state: "supported", source: "admin", checked_at: Time.current)
      mock_llm_models_response(base_url, body: { object: "list", data: [] }.to_json)

      # A fresh instance, as every caller builds one: the adapter memoises the
      # fetched list within a run.
      described_class.new(connection).call

      expect(connection.capability_verdicts.pluck(:source)).to eq(["admin"])
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

    it "falls back to the registry for a server that lists bare ids" do
      mock_llm_models_response(base_url, models: [{ id: "gpt-4o", object: "model" }])

      service.call

      llm_model = connection.models.find_by(external_id: "gpt-4o")
      expect(llm_model.name).to eq("GPT-4o")
      expect(llm_model.context_window).to eq(128_000)
    end

    it "keeps an administrator's display name over the one the registry publishes" do
      mock_llm_models_response(base_url, models: [{ id: "gpt-4o", object: "model" }])
      service.call
      connection.models.find_by(external_id: "gpt-4o").update!(display_name: "The house model")

      described_class.new(connection).call

      expect(connection.models.find_by(external_id: "gpt-4o").display_name).to eq("The house model")
    end
  end
end
