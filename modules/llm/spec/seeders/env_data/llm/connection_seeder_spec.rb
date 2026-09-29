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

RSpec.describe EnvData::Llm::ConnectionSeeder do
  subject(:seed) { described_class.new(seed_data).seed! }

  let(:seed_data) { Source::SeedData.new({}) }

  it "does not seed a connection without configuration" do
    expect { seed }.not_to change(LlmConnection, :count)
  end

  # On a fresh installation the seed runs before any model synchronisation, so
  # the model the environment names has no row yet. Provisioning enters it the
  # way an administrator would, and the refresh confirms it later.
  context "with a default model configured on a fresh installation", with_settings: {
    llm_connection: {
      "base_url" => "https://example.com/v1",
      "api_key" => "sk-from-env",
      "default_chat_model" => "qwen3.6-35b-a3b"
    }
  } do
    it "seeds the connection without contacting the server" do
      expect { seed }.to change(LlmConnection, :count).from(0).to(1)

      connection = LlmConnection.first
      expect(connection.default_chat_model.external_id).to eq("qwen3.6-35b-a3b")
      expect(connection.api_key).to eq("sk-from-env")
    end

    it "enqueues the initial catalogue fill" do
      expect { seed }.to have_enqueued_job(Llm::SyncModelsJob)
    end
  end

  # The seeder runs on every container start, so a refresh here would repeatedly
  # overwrite a list an administrator has curated. The stale warning on the AI
  # models tab asks for the refresh instead.
  context "when the environment moves a stored catalogue to another host", with_settings: {
    llm_connection: { "base_url" => "https://other.example.com/v1", "api_key" => "sk-from-env" }
  } do
    let!(:connection) do
      create(:llm_connection, :with_models, base_url: "https://example.com/v1", api_key: "sk-from-env")
        .tap { |record| record.update!(connection_fingerprint: record.settings_fingerprint) }
    end

    it "keeps the stored models and flags them as stale" do
      expect { seed }.not_to have_enqueued_job(Llm::SyncModelsJob)

      expect(connection.reload.base_url).to eq("https://other.example.com/v1")
      expect(connection.models.count).to eq(2)
      expect(connection).to be_models_stale
    end
  end

  # An unknown verdict is the normal state of a self-hosted server: nothing has
  # probed the row yet. Provisioning must not fail on it, or the identical
  # configuration would seed on a fresh installation and raise on the next start.
  context "with an embedding default nothing has probed", with_settings: {
    llm_connection: {
      "base_url" => "https://example.com/v1",
      "default_embedding_model" => "bge-m3"
    }
  } do
    before { create(:llm_connection, :with_models, base_url: "https://example.com/v1") }

    it "provisions the default" do
      seed

      expect(LlmConnection.first.default_embedding_model.external_id).to eq("bge-m3")
    end
  end

  context "with an embedding default the server has ruled out", with_settings: {
    llm_connection: {
      "base_url" => "https://example.com/v1",
      "default_embedding_model" => "bge-m3"
    }
  } do
    before do
      create(:llm_connection, :with_models, base_url: "https://example.com/v1")
        .capability_verdicts
        .create!(model_id: "bge-m3", capability: "embeddings",
                 state: "unsupported", source: "probe", checked_at: Time.current)
    end

    it "refuses to provision it" do
      expect { seed }.to raise_error(/create embeddings/)
    end
  end

  context "without an enabled key", with_settings: {
    llm_connection: { "base_url" => "https://example.com/v1" }
  } do
    it "keeps the stored features switch" do
      Setting.llm_features_enabled = false

      seed

      expect(Setting.llm_features_enabled?).to be(false)
    end
  end

  context "when the features switch itself is set through the environment", with_settings: {
    llm_connection: { "base_url" => "https://example.com/v1", "enabled" => "false" }
  } do
    before do
      allow(Settings::Definition[:llm_features_enabled]).to receive_messages(writable?: false, value: true)
    end

    it "provisions the connection and leaves the switch to the environment" do
      expect { seed }.to change(LlmConnection, :count).from(0).to(1)

      expect(Setting.llm_features_enabled?).to be(true)
    end
  end

  # Nested environment keys come out lowercased with underscores, which cannot
  # spell a header name such as api-version, so the headers arrive as one JSON
  # object. configuration.yml hands over a Hash instead.
  context "with custom headers as a JSON object", with_settings: {
    llm_connection: {
      "base_url" => "https://example.com/v1",
      "custom_headers" => '{"api-version":"2024-02-01","X-Portkey-Api-Key":"pk-from-env"}'
    }
  } do
    it "stores the header names exactly as given" do
      seed

      expect(LlmConnection.first.custom_headers)
        .to eq("api-version" => "2024-02-01", "X-Portkey-Api-Key" => "pk-from-env")
    end
  end

  context "with custom headers as a Hash from configuration.yml", with_settings: {
    llm_connection: { "base_url" => "https://example.com/v1", "custom_headers" => { "api-version" => "2024-02-01" } }
  } do
    it "stores the header names exactly as given" do
      seed

      expect(LlmConnection.first.custom_headers).to eq("api-version" => "2024-02-01")
    end
  end

  [
    ["invalid JSON", '{"api-version":'],
    ["a JSON array", '["api-version"]'],
    ["a non-string header value", '{"x-retries":3}'],
    ["a scalar", 3]
  ].each do |description, value|
    context "with custom headers given as #{description}", with_settings: {
      llm_connection: { "base_url" => "https://example.com/v1", "custom_headers" => value }
    } do
      it "refuses the configuration and names the variable" do
        expect { seed }.to raise_error(/CUSTOM__HEADERS must be a JSON object/)

        expect(LlmConnection.count).to eq(0)
      end
    end
  end

  # The environment is the source of truth while the form is read-only under it,
  # so a value removed from the environment must not linger in the database.
  context "when a previously set key is removed from the environment", with_settings: {
    llm_connection: { "base_url" => "https://example.com/v1" }
  } do
    before do
      connection = create(:llm_connection, base_url: "https://example.com/v1", api_key: "sk-stale",
                                           custom_headers: { "api-version" => "2024-02-01" })
      connection.update!(default_chat_model: create(:llm_model, llm_connection: connection,
                                                                external_id: "old-default"))
    end

    it "clears the values the environment no longer provides" do
      expect { seed }.not_to change(LlmConnection, :count)

      connection = LlmConnection.first
      expect(connection.api_key).to be_nil
      expect(connection.default_chat_model_id).to be_nil
      expect(connection.custom_headers).to eq({})
      expect(connection.base_url).to eq("https://example.com/v1")
    end
  end
end
