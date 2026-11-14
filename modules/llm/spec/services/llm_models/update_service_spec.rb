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

RSpec.describe LlmModels::UpdateService do
  let(:admin) { create(:admin) }
  let(:connection) { create(:llm_connection, :provisioned_from_env, env_fingerprint: "seeded") }
  let!(:llm_model) { create(:llm_model, :manual, llm_connection: connection, external_id: "bge-m3") }
  let(:params) { { external_id: "bge-m3-v2" } }

  subject(:result) { described_class.new(user: admin, model: llm_model).call(**params) }

  describe "renaming" do
    before do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3")
      create(:llm_feature_binding, llm_connection: connection, feature_key: "description_assistant", model_id: "bge-m3")
    end

    it "carries verdicts and bindings over to the new identifier" do
      expect(result).to be_success
      expect(connection.capability_verdicts.pluck(:model_id)).to eq(["bge-m3-v2"])
      expect(connection.feature_bindings.pluck(:model_id)).to eq(["bge-m3-v2"])
    end

    it "judges the rename under the connection's advisory lock" do
      allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction).and_call_original

      result

      expect(OpenProject::Mutex).to have_received(:with_advisory_lock_transaction).with(connection)
    end

    it "leaves the environment's claim alone when the model is no default" do
      result

      expect(connection.reload.env_provisioned_at).to be_present
    end

    it "takes the connection out of the environment's hands when it renames a default" do
      connection.update_columns(default_chat_model_id: llm_model.id)

      result

      expect(connection.reload).to have_attributes(env_provisioned_at: nil, env_fingerprint: nil)
    end

    context "when the environment still names the model as a default" do
      before do
        connection.update_columns(default_chat_model_id: llm_model.id)
        allow(Setting).to receive(:llm_connection).and_return({ "default_chat_model" => "bge-m3" })
      end

      it "refuses" do
        expect(result.errors.symbols_for(:base)).to eq([:configured_from_env])
        expect(llm_model.reload.external_id).to eq("bge-m3")
      end
    end

    context "when renaming onto an identifier with leftover verdicts" do
      before do
        create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3-v2", capability: "vision")
        create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3", capability: "vision")
      end

      it "rolls the rename back and reports the conflict" do
        expect(result).to be_failure
        expect(result.errors.symbols_for(:external_id)).to eq([:conflicting_capabilities])
        expect(llm_model.reload.external_id).to eq("bge-m3")
        expect(connection.capability_verdicts.for_model("bge-m3").count).to eq(2)
      end
    end
  end

  context "when another rename committed after the model was loaded" do
    let(:loaded_before) { LlmModel.find(llm_model.id) }

    before do
      loaded_before
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3")
      described_class.new(user: admin, model: llm_model).call(external_id: "bge-m3-first")
    end

    it "cascades from the committed identifier" do
      result = described_class.new(user: admin, model: loaded_before).call(**params)

      expect(result).to be_success
      expect(connection.capability_verdicts.pluck(:model_id)).to eq(["bge-m3-v2"])
    end
  end

  context "when asserting a state that is not one on an embedding model without choosing a type" do
    let(:params) { { capability_vision: "maybe" } }

    before do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3", capability: "embeddings",
                                      state: "supported", source: "admin")
    end

    it "fails validation" do
      expect(result.errors.symbols_for(:capability_vision)).to eq([:inclusion])
    end
  end

  context "for a discovered model" do
    let!(:llm_model) { create(:llm_model, llm_connection: connection, external_id: "bge-m3") }

    it "refuses to rename it" do
      expect(result.errors.symbols_for(:external_id)).to eq([:error_readonly])
      expect(llm_model.reload.external_id).to eq("bge-m3")
    end
  end

  describe "the model type" do
    before do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3", capability: "embeddings",
                                      state: "unsupported", source: "probe")
    end

    context "when the type stays the same" do
      let(:params) { { model_type: "chat", display_name: "BGE" } }

      it "leaves the detected verdict alone" do
        expect(result).to be_success
        expect(llm_model.verdict_for(:embeddings).source).to eq("probe")
      end
    end

    context "when the type changes" do
      let(:params) { { model_type: "embedding", external_id: "bge-m3-v2" } }

      it "asserts it under the new identifier" do
        expect(result).to be_success
        expect(connection.capability_verdicts.for_model("bge-m3-v2").pluck(:capability, :state, :source))
          .to eq([%w[embeddings supported admin]])
      end
    end
  end
end
