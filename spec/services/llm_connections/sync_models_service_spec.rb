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

    # on_delete: :nullify on the two default_*_model_id foreign keys.
    it "lets go of a connection default that named a model the previous server offered" do
      connection.update!(default_chat_model: connection.models.find_by(external_id: "qwen3.6-27b"))
      mock_llm_models_response("https://elsewhere.example/v1", response_code: 405)

      service.call

      expect(connection.reload.default_chat_model_id).to be_nil
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
      connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                             state: "supported", source: "probe", checked_at: Time.current)
      connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "vision",
                                             state: "supported", source: "probe", checked_at: Time.current)
      mock_llm_models_response(base_url, models: [{ id: "qwen3.6-27b", object: "model" }])

      described_class.new(connection).call

      expect(connection.models.find_by(external_id: "bge-m3")).to be_withdrawn
      expect(connection.models.find_by(external_id: "qwen3.6-27b")).to be_active
      expect(connection.capability_verdicts.pluck(:model_id)).to eq(["qwen3.6-27b"])
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

      expect(described_class.new(connection).call).to be_failure
    end
  end
end
