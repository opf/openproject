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

RSpec.describe LlmModel do
  let(:connection) { create(:llm_connection) }
  let(:llm_model) { create(:llm_model, llm_connection: connection, external_id: "bge-m3") }

  describe "validations" do
    it "requires an identifier unique within the connection" do
      create(:llm_model, llm_connection: connection, external_id: "bge-m3")

      expect(build(:llm_model, llm_connection: connection, external_id: "")).not_to be_valid
      expect(build(:llm_model, llm_connection: connection, external_id: "bge-m3")).not_to be_valid
      expect(build(:llm_model, external_id: "bge-m3")).to be_valid
    end

    it "bounds the identifier length" do
      too_long = "m" * (described_class::MAX_EXTERNAL_ID_LENGTH + 1)

      expect(build(:llm_model, llm_connection: connection, external_id: too_long)).not_to be_valid
    end
  end

  describe "#name" do
    it "prefers the administrator's name, then the reported one, then the identifier" do
      llm_model.raw_metadata = { "name" => "BGE M3" }
      expect(llm_model.name).to eq("BGE M3")

      llm_model.display_name = "Embeddings"
      expect(llm_model.name).to eq("Embeddings")

      llm_model.assign_attributes(display_name: "", raw_metadata: {})
      expect(llm_model.name).to eq("bge-m3")
    end
  end

  describe "#context_window" do
    it "prefers the administrator's figure, then the server's, then the registry's" do
      llm_model.raw_metadata = { "context_window" => 4_096 }
      expect([llm_model.context_window, llm_model.context_window_source]).to eq([4_096, :registry])

      llm_model.raw_metadata = llm_model.raw_metadata.merge("max_model_len" => 8_192)
      expect([llm_model.context_window, llm_model.context_window_source]).to eq([8_192, :server])

      llm_model.admin_context_window = "16384"
      expect([llm_model.context_window, llm_model.context_window_source]).to eq([16_384, :admin])
    end

    it "reveals the reported figure again when the administrator's is cleared" do
      llm_model.raw_metadata = { "max_model_len" => 8_192, "admin_context_window" => 16_384 }

      llm_model.admin_context_window = ""

      expect(llm_model.context_window).to eq(8_192)
      expect(llm_model.raw_metadata).not_to have_key("admin_context_window")
    end

    %w[abc -5 0].each do |value|
      it "rejects #{value.inspect} as the administrator's figure" do
        llm_model.admin_context_window = value

        expect(llm_model).not_to be_valid
        expect(llm_model.errors.symbols_for(:admin_context_window)).to be_present
      end
    end
  end

  describe "capability attributes" do
    it "shows only an administrator's own assertion as the value" do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3", capability: "vision",
                                      state: "supported", source: "admin")
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3", capability: "reasoning",
                                      state: "supported", source: "metadata")

      expect(llm_model.capability_vision).to eq("supported")
      expect(llm_model.capability_reasoning).to be_nil
    end

    it "keeps a submitted value until it is saved" do
      llm_model.capability_vision = "unsupported"
      llm_model.capability_reasoning = ""

      expect(llm_model.capability_overrides).to eq("vision" => "unsupported", "reasoning" => nil)
      expect(llm_model.capability_vision).to eq("unsupported")
    end
  end

  describe "#cascade_rename!" do
    let(:connection) { create(:llm_connection, :provisioned_from_env, env_fingerprint: "seeded") }

    before do
      llm_model
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3")
      create(:llm_feature_binding, llm_connection: connection, feature_key: "description_assistant", model_id: "bge-m3")
    end

    it "carries verdicts and bindings over to the new identifier" do
      llm_model.update!(external_id: "bge-m3-v2")
      llm_model.cascade_rename!("bge-m3")

      expect(connection.capability_verdicts.pluck(:model_id)).to eq(["bge-m3-v2"])
      expect(connection.feature_bindings.pluck(:model_id)).to eq(["bge-m3-v2"])
    end

    it "takes the connection out of the environment's hands when it renames a default" do
      connection.update_columns(default_chat_model_id: llm_model.id)
      llm_model.update!(external_id: "bge-m3-v2")

      llm_model.cascade_rename!("bge-m3")

      expect(connection.reload).to have_attributes(env_provisioned_at: nil, env_fingerprint: nil)
    end

    it "leaves the environment's claim alone when the model is no default" do
      llm_model.update!(external_id: "bge-m3-v2")

      llm_model.cascade_rename!("bge-m3")

      expect(connection.reload.env_provisioned_at).to be_present
    end
  end

  describe "#cascade_delete!" do
    it "removes the model's verdicts and the defaults that named it" do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3")
      create(:llm_capability_verdict, llm_connection: connection, model_id: "another")
      connection.update_columns(default_embedding_model_id: llm_model.id)

      llm_model.cascade_delete!

      expect(connection.capability_verdicts.pluck(:model_id)).to eq(["another"])
      expect(connection.reload.default_embedding_model_id).to be_nil
    end
  end

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
      create(:llm_capability_verdict, llm_connection: connection, model_id: llm_model.external_id, capability: "embeddings",
                                      state: "supported", source: "admin")

      expect(llm_model).to be_embedding
      expect(llm_model.model_type).to eq(:embedding)
    end

    it "is chat when the embeddings verdict is unknown" do
      create(:llm_capability_verdict, llm_connection: connection, model_id: llm_model.external_id, capability: "embeddings",
                                      state: "unknown", source: "metadata")

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
      create(:llm_feature_binding, llm_connection: connection, feature_key: "description_assistant", model_id: "qwen3.6-27b")

      resolution = Llm::Runtime.for(:description_assistant)

      expect(connection.available_model_ids).to include("qwen3.6-27b")
      expect(resolution).to be_ready
      expect(resolution.model_id).to eq("qwen3.6-27b")
    end
  end
end
