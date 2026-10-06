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

RSpec.describe LlmConnections::EnvSyncService do
  subject(:result) { described_class.new(env_config).call }

  let!(:connection) do
    create(:llm_connection, :with_models, base_url: "https://example.com/v1", api_key: "sk-stored")
  end

  context "with a valid configuration" do
    let(:env_config) do
      { "base_url" => "https://other.example.com/v1", "api_key" => "sk-from-env", "default_chat_model" => "qwen3.6-27b" }
    end

    it "writes the connection and its default model" do
      expect(result).to be_success

      connection.reload
      expect(connection.base_url).to eq("https://other.example.com/v1")
      expect(connection.default_chat_model.external_id).to eq("qwen3.6-27b")
    end

    it "marks the connection as written by the environment" do
      expect(result).to be_success

      expect(connection.reload.env_provisioned_at).to be_present
    end

    # The second write would change the marker if it carried another time, and
    # clear it if it carried none.
    it "stamps both of its writes with the same time" do
      expect(result).to be_success

      expect(result.result.saved_changes).not_to have_key("env_provisioned_at")
    end
  end

  context "when an administrator's save commits while the seed waits for the connection's lock" do
    let(:env_config) { { "base_url" => "https://example.com/v1", "api_key" => "sk-stored" } }

    before do
      saved = false
      allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction).and_wrap_original do |original, *args, &block|
        LlmConnection.where(id: connection.id).update_all(base_url: "https://admin.example/v1") unless saved
        saved = true
        original.call(*args, &block)
      end
    end

    it "writes the environment's values over it" do
      expect(result).to be_success

      expect(connection.reload.base_url).to eq("https://example.com/v1")
    end
  end

  context "with custom headers as a JSON object" do
    let(:env_config) do
      { "base_url" => "https://example.com/v1", "custom_headers" => '{"api-version":"2024-02-01","X-Gateway":"on"}' }
    end

    it "stores the header names exactly as given" do
      expect(result).to be_success
      expect(connection.reload.custom_headers).to eq("api-version" => "2024-02-01", "X-Gateway" => "on")
    end
  end

  context "with custom headers as a Hash" do
    let(:env_config) do
      { "base_url" => "https://example.com/v1", "custom_headers" => { "api-version" => "2024-02-01" } }
    end

    it "stores the header names exactly as given" do
      expect(result).to be_success
      expect(connection.reload.custom_headers).to eq("api-version" => "2024-02-01")
    end
  end

  context "without custom headers while some are stored" do
    let(:env_config) { { "base_url" => "https://example.com/v1" } }

    before { connection.update!(custom_headers: { "api-version" => "2024-02-01" }) }

    it "clears them" do
      expect(result).to be_success
      expect(connection.reload.custom_headers).to eq({})
    end
  end

  context "with custom headers that are not a JSON object" do
    let(:env_config) { { "base_url" => "https://example.com/v1", "custom_headers" => '["api-version"]' } }

    before { connection.update!(custom_headers: { "api-version" => "2024-02-01" }) }

    it "fails and keeps the stored headers" do
      expect(result).to be_failure
      expect(result.errors).to be_of_kind(:custom_headers, :invalid)
      expect(connection.reload.custom_headers).to eq("api-version" => "2024-02-01")
    end
  end

  context "when the default model cannot be bound" do
    let(:env_config) do
      { "base_url" => "https://other.example.com/v1", "api_key" => "sk-from-env", "default_chat_model" => "bge-m3" }
    end

    before do
      connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                             state: "supported", source: "admin", checked_at: Time.current)
    end

    it "fails and keeps the stored connection as it was" do
      expect(result).to be_failure

      connection.reload
      expect(connection.base_url).to eq("https://example.com/v1")
      expect(connection.api_key).to eq("sk-stored")
      expect(connection.default_chat_model_id).to be_nil
    end

    it "does not mark the connection as written by the environment" do
      expect(result).to be_failure

      expect(connection.reload.env_provisioned_at).to be_nil
    end

    it "keeps the time the environment last wrote the connection" do
      applied_at = 1.day.ago.change(usec: 0)
      connection.update_columns(env_provisioned_at: applied_at)

      expect(result).to be_failure

      expect(connection.reload.env_provisioned_at).to eq(applied_at)
    end
  end

  context "when the connection itself is invalid" do
    let(:env_config) { { "base_url" => "not a url" } }

    it "fails and keeps the stored connection as it was" do
      expect(result).to be_failure
      expect(connection.reload.base_url).to eq("https://example.com/v1")
    end

    it "does not mark the connection as written by the environment" do
      expect(result).to be_failure

      expect(connection.reload.env_provisioned_at).to be_nil
    end

    it "keeps the time the environment last wrote the connection" do
      applied_at = 1.day.ago.change(usec: 0)
      connection.update_columns(env_provisioned_at: applied_at)

      expect(result).to be_failure

      expect(connection.reload.env_provisioned_at).to eq(applied_at)
    end
  end
end
