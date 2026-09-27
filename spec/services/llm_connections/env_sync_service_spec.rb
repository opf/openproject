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
  end

  context "when the connection itself is invalid" do
    let(:env_config) { { "base_url" => "not a url" } }

    it "fails and keeps the stored connection as it was" do
      expect(result).to be_failure
      expect(connection.reload.base_url).to eq("https://example.com/v1")
    end
  end
end
