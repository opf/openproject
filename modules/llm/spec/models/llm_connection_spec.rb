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

RSpec.describe LlmConnection do
  describe "#api_key", with_config: { "database_cipher_key" => "secret" } do
    it "is stored as it was given, even with a cipher key configured" do
      connection = create(:llm_connection, api_key: "sk-plain-key")

      expect(connection.reload.api_key).to eq("sk-plain-key")
      expect(described_class.where(id: connection.id).pick(:api_key)).to eq("sk-plain-key")
    end
  end

  describe "#api_key_stored?" do
    it "is false for a connection that was never saved" do
      expect(build(:llm_connection, api_key: "sk-test-key")).not_to be_api_key_stored
    end

    it "is false for a saved connection without a key" do
      expect(create(:llm_connection, api_key: nil)).not_to be_api_key_stored
    end

    it "is true for a saved connection with a key" do
      expect(create(:llm_connection, api_key: "sk-test-key")).to be_api_key_stored
    end

    it "is false when a key was assigned but the save failed" do
      connection = create(:llm_connection, api_key: nil)
      connection.assign_attributes(api_key: "sk-test-key", base_url: "")

      expect(connection.save).to be(false)
      expect(connection).not_to be_api_key_stored
    end
  end

  describe "the single active connection" do
    it "allows only one connection to be active" do
      create(:llm_connection)
      second = build(:llm_connection, active: true)

      expect(second).not_to be_valid
      expect(second.errors).to be_of_kind(:base, :singleton)
    end

    it "allows any number of inactive connections beside it" do
      create(:llm_connection)

      expect(build(:llm_connection, active: false)).to be_valid
    end

    it "is capped by the database as well as the validation" do
      create(:llm_connection)
      second = build(:llm_connection, active: true)

      expect { second.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "hands out the active connection, unsaved when there is none" do
      expect(described_class.active_connection).to be_new_record
      expect(described_class.active_connection).to be_active

      connection = create(:llm_connection)

      expect(described_class.active_connection).to eq(connection)
    end
  end

  describe "#settings_fingerprint" do
    subject(:connection) { build(:llm_connection, base_url: "https://example.com/v1", api_key: "sk-test") }

    it "changes with the API format" do
      expect { connection.api_format = "anthropic" }.to change(connection, :settings_fingerprint)
    end

    it "changes with the host URL" do
      expect { connection.base_url = "https://elsewhere.example/v1" }.to change(connection, :settings_fingerprint)
    end

    it "does not change with the API key" do
      expect { connection.api_key = "sk-rotated" }.not_to change(connection, :settings_fingerprint)
    end
  end

  describe "#models_stale?" do
    subject(:connection) { create(:llm_connection, base_url: "https://example.com/v1", api_key: "sk-test") }

    it "is false while no model list has been fetched" do
      expect(connection).not_to be_models_stale
    end

    it "is false while the settings still match the fetched list" do
      connection.update!(connection_fingerprint: connection.settings_fingerprint)

      expect(connection).not_to be_models_stale
    end

    it "is true once a connection setting changed" do
      connection.update!(connection_fingerprint: connection.settings_fingerprint)
      connection.update!(base_url: "https://elsewhere.example/v1")

      expect(connection).to be_models_stale
    end

    it "stays false when only the API key is rotated" do
      connection.update!(connection_fingerprint: connection.settings_fingerprint)
      connection.update!(api_key: "sk-rotated")

      expect(connection).not_to be_models_stale
    end
  end

  describe "#chat_models" do
    let(:connection) { create(:llm_connection, :with_models) }

    before do
      connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                             state: "supported", source: "probe", checked_at: Time.current)
    end

    it "lists the active models that are not embedding models, by identifier" do
      create(:llm_model, llm_connection: connection, external_id: "a-chat-model")
      create(:llm_model, :withdrawn, llm_connection: connection, external_id: "b-withdrawn")

      expect(connection.chat_models.map(&:external_id)).to eq(%w[a-chat-model qwen3.6-27b])
    end

    it "does not query once per model" do
      query_count = -> { ActiveRecord::QueryRecorder.new { connection.chat_models.to_a }.count }
      with_two_models = query_count.call

      create_list(:llm_model, 3, llm_connection: connection)

      expect(query_count.call).to eq(with_two_models)
    end
  end

  describe "#embedding_models" do
    let(:connection) { create(:llm_connection, :with_models) }

    before do
      connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                             state: "supported", source: "probe", checked_at: Time.current)
    end

    it "lists the active models that can create embeddings, by identifier" do
      create(:llm_model, :withdrawn, llm_connection: connection, external_id: "a-withdrawn")
      connection.capability_verdicts.create!(model_id: "a-withdrawn", capability: "embeddings",
                                             state: "supported", source: "probe", checked_at: Time.current)

      expect(connection.embedding_models.map(&:external_id)).to eq(%w[bge-m3])
    end

    it "does not query once per model" do
      query_count = -> { ActiveRecord::QueryRecorder.new { connection.embedding_models.to_a }.count }
      with_two_models = query_count.call

      create_list(:llm_model, 3, llm_connection: connection)

      expect(query_count.call).to eq(with_two_models)
    end
  end

  describe ".available?" do
    context "with the feature flag and the setting on",
            with_flag: { llm_connection: true },
            with_settings: { llm_features_enabled: true } do
      it "is true when an active connection is stored" do
        create(:llm_connection)

        expect(described_class).to be_available
      end

      it "is false when only an inactive connection is stored" do
        create(:llm_connection, active: false)

        expect(described_class).not_to be_available
      end
    end

    it "is false with the feature flag off",
       with_flag: { llm_connection: false },
       with_settings: { llm_features_enabled: true } do
      create(:llm_connection)

      expect(described_class).not_to be_available
    end

    it "is false with the setting off",
       with_flag: { llm_connection: true },
       with_settings: { llm_features_enabled: false } do
      create(:llm_connection)

      expect(described_class).not_to be_available
    end
  end

  describe "provisioning from the environment" do
    context "with the environment configuring a connection",
            with_settings: { llm_connection: { "base_url" => "https://example.com/v1" } } do
      it "is pending, not locked, while no connection is stored" do
        connection = described_class.active_connection

        expect(connection).not_to be_configured_from_env
        expect(connection).to be_env_pending
      end

      it "is pending, not locked, for a connection an administrator saved" do
        connection = create(:llm_connection)

        expect(connection).not_to be_configured_from_env
        expect(connection).to be_env_pending
      end

      it "is locked once the environment has written the connection" do
        connection = create(:llm_connection, :provisioned_from_env)

        expect(connection).to be_configured_from_env
        expect(connection).not_to be_env_pending
      end

      it "stays locked while the stored marker is only cleared in memory" do
        connection = create(:llm_connection, :provisioned_from_env)
        connection.env_provisioned_at = nil

        expect(connection).to be_configured_from_env
      end
    end

    context "without the environment configuring a connection" do
      it "is neither locked nor pending for a connection the environment once wrote" do
        connection = create(:llm_connection, :provisioned_from_env)

        expect(connection).not_to be_configured_from_env
        expect(connection).not_to be_env_pending
      end

      it "is neither locked nor pending for a connection an administrator saved" do
        connection = create(:llm_connection)

        expect(connection).not_to be_configured_from_env
        expect(connection).not_to be_env_pending
      end
    end
  end

  describe "#env_named_default?" do
    let(:connection) { create(:llm_connection, :provisioned_from_env) }
    let(:chat_model) { create(:llm_model, :manual, llm_connection: connection) }
    let(:embedding_model) { create(:llm_model, :manual, llm_connection: connection) }
    let(:other_model) { create(:llm_model, :manual, llm_connection: connection) }

    before do
      connection.update_columns(default_chat_model_id: chat_model.id, default_embedding_model_id: embedding_model.id)
    end

    context "with the environment configuring the connection",
            with_settings: { llm_connection: { "base_url" => "https://example.com/v1" } } do
      it "holds for both defaults" do
        expect(connection.env_named_default?(chat_model)).to be(true)
        expect(connection.env_named_default?(embedding_model)).to be(true)
      end

      it "does not hold for any other model" do
        expect(connection.env_named_default?(other_model)).to be(false)
      end

      it "goes by the stored defaults, not by one only assigned" do
        connection.default_chat_model_id = other_model.id

        expect(connection.env_named_default?(chat_model)).to be(true)
        expect(connection.env_named_default?(other_model)).to be(false)
      end

      it "does not hold before the environment has written the connection" do
        connection.update_columns(env_provisioned_at: nil)

        expect(connection.env_named_default?(chat_model)).to be(false)
      end
    end

    it "does not hold once the environment no longer configures the connection" do
      expect(connection.env_named_default?(chat_model)).to be(false)
    end
  end

  # The environment seeder and direct writes reach the model without the
  # contract, so these have to hold on the model itself.
  describe "validations" do
    it "requires an identifier, rather than failing on the NOT NULL column" do
      connection = build(:llm_connection, identifier: nil)

      expect(connection).not_to be_valid
      expect(connection.errors).to be_of_kind(:identifier, :blank)
    end

    it "refuses a format no adapter serves" do
      connection = build(:llm_connection, api_format: "no-such-format")

      expect(connection).not_to be_valid
      expect(connection.errors).to be_of_kind(:api_format, :inclusion)
    end

    it "accepts custom headers that map names to plain strings" do
      expect(build(:llm_connection, custom_headers: { "api-version" => "2024-02-01" })).to be_valid
    end

    it "refuses a header value that is not a string" do
      connection = build(:llm_connection, custom_headers: { "x-retries" => 3 })

      expect(connection).not_to be_valid
      expect(connection.errors).to be_of_kind(:custom_headers, :invalid)
    end

    it "refuses a nested header value" do
      expect(build(:llm_connection, custom_headers: { "x-gateway" => { "key" => "value" } })).not_to be_valid
    end

    it "refuses a header value carrying a line break" do
      expect(build(:llm_connection, custom_headers: { "x-gateway" => "one\r\nInjected: two" })).not_to be_valid
    end

    it "refuses a header name carrying a line break" do
      connection = build(:llm_connection, custom_headers: { "x-gateway\r\nInjected" => "two" })

      expect(connection).not_to be_valid
      expect(connection.errors).to be_of_kind(:custom_headers, :invalid)
    end

    it "refuses a header name that is not an HTTP token", :aggregate_failures do
      ["x gateway", "x-gateway:", "x-gäteway", "(x-gateway)", ""].each do |name|
        expect(build(:llm_connection, custom_headers: { name => "value" })).not_to be_valid, name.inspect
      end
    end

    it "accepts a header name built from any HTTP token character" do
      expect(build(:llm_connection, custom_headers: { "X-Gateway_1.v2!\#$%&'*+^`|~" => "value" })).to be_valid
    end

    it "accepts an absolute http or https base URL", :aggregate_failures do
      %w[https://example.com/v1 http://10.0.0.5:8000/v1].each do |base_url|
        expect(build(:llm_connection, base_url:)).to be_valid, base_url
      end
    end

    it "refuses a base URL without an http scheme or a host", :aggregate_failures do
      %w[//host/path http:host http:// localhost:8080/v1 ftp://example.com].each do |base_url|
        connection = build(:llm_connection, base_url:)

        expect(connection).not_to be_valid, base_url
        expect(connection.errors).to be_of_kind(:base_url, :invalid_url)
      end
    end

    it "refuses a base URL that cannot be parsed" do
      connection = build(:llm_connection, base_url: "https://example.com/a b")

      expect(connection).not_to be_valid
      expect(connection.errors).to be_of_kind(:base_url, :invalid_url)
    end
  end
end
