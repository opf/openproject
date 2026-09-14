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
      connection.update_columns(base_url: "https://elsewhere.example/v1",
                                connection_fingerprint: "the-previous-deployment")
    end

    it "invalidates the old models and verdicts even when the new server offers no list" do
      mock_llm_models_response("https://elsewhere.example/v1", response_code: 404)

      result = service.call

      expect(result).to be_failure
      expect(connection.capability_verdicts).to be_empty
      expect(connection.models.active).to be_empty
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
end
