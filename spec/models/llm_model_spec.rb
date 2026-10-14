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

RSpec.describe LlmModel do
  let(:connection) { create(:llm_connection) }
  let(:llm_model) { create(:llm_model, llm_connection: connection, external_id: "bge-m3") }

  describe "#model_type" do
    it "is chat while nothing says the model embeds" do
      expect(llm_model).not_to be_embedding
      expect(llm_model.model_type).to eq(:chat)
    end

    it "is unset on a model being added until one is chosen" do
      expect(connection.models.new(external_id: "bge-m3").model_type).to be_nil
      expect(connection.models.new(external_id: "bge-m3", model_type: "chat").model_type).to eq(:chat)
    end

    it "is embedding once the embeddings verdict says so" do
      connection.capability_verdicts.create!(model_id: llm_model.external_id, capability: "embeddings",
                                             state: "supported", source: "admin", checked_at: Time.current)

      expect(llm_model).to be_embedding
      expect(llm_model.model_type).to eq(:embedding)
    end

    it "is chat when the embeddings verdict is unknown" do
      connection.capability_verdicts.create!(model_id: llm_model.external_id, capability: "embeddings",
                                             state: "unknown", source: "metadata", checked_at: Time.current)

      expect(llm_model.model_type).to eq(:chat)
    end
  end

  describe "withdrawal", :llm_server_helpers, :webmock, with_flag: { llm_connection: true } do
    let(:base_url) { "https://example.com/v1" }
    let!(:connection) { create(:llm_connection, :with_models, base_url:) }
    let(:model) { connection.models.find_by(external_id: "qwen3.6-27b") }

    it "only describes a discovered model the server stopped reporting" do
      withdrawn = create(:llm_model, :withdrawn, llm_connection: connection, external_id: "gone")
      typed = create(:llm_model, :manual, :withdrawn, llm_connection: connection, external_id: "hand-typed")

      expect(withdrawn).to be_withdrawn
      expect(typed).not_to be_withdrawn
      expect(model).not_to be_withdrawn
    end
  end

  describe "a feature binding", :llm_server_helpers, :webmock,
           with_flag: { llm_connection: true }, with_settings: { llm_features_enabled: true } do
    let!(:connection) { create(:llm_connection, :with_models, base_url: "https://example.com/v1") }

    it "keeps the bound model available and resolves the feature to it" do
      connection.feature_bindings.create!(feature_key: "description_assistant", model_id: "qwen3.6-27b")

      resolution = Llm::Runtime.for(:description_assistant)

      expect(connection.available_model_ids).to include("qwen3.6-27b")
      expect(resolution).to be_ready
      expect(resolution.model_id).to eq("qwen3.6-27b")
    end
  end
end
