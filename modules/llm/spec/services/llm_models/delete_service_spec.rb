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

RSpec.describe LlmModels::DeleteService do
  let(:admin) { create(:admin) }
  let(:connection) { create(:llm_connection, :provisioned_from_env, env_fingerprint: "seeded") }
  let!(:llm_model) { create(:llm_model, :manual, llm_connection: connection, external_id: "bge-m3") }

  subject(:result) { described_class.new(user: admin, model: llm_model).call }

  it "removes the model, its verdicts and the defaults that named it" do
    create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3")
    create(:llm_capability_verdict, llm_connection: connection, model_id: "another")
    connection.update_columns(default_embedding_model_id: llm_model.id)

    expect(result).to be_success
    expect(LlmModel.where(id: llm_model.id)).to be_empty
    expect(connection.capability_verdicts.pluck(:model_id)).to eq(["another"])
    expect(connection.reload).to have_attributes(default_embedding_model_id: nil, env_provisioned_at: nil)
  end

  it "leaves the environment's claim alone when the model is no default" do
    result

    expect(connection.reload.env_provisioned_at).to be_present
  end

  context "when the model was deleted after it was loaded" do
    let(:loaded_before) { LlmModel.find(llm_model.id) }

    before do
      loaded_before
      described_class.new(user: admin, model: llm_model).call
      create(:llm_model, :manual, llm_connection: connection, external_id: "bge-m3")
      create(:llm_capability_verdict, llm_connection: connection, model_id: "bge-m3")
    end

    it "leaves the model re-added under the same identifier alone" do
      expect { described_class.new(user: admin, model: loaded_before).call }
        .to raise_error(ActiveRecord::RecordNotFound)
      expect(connection.capability_verdicts.for_model("bge-m3")).to exist
    end
  end

  context "for a discovered model" do
    let!(:llm_model) { create(:llm_model, llm_connection: connection) }

    it "refuses" do
      expect(result.errors.symbols_for(:base)).to eq([:discovered])
      expect(LlmModel.where(id: llm_model.id)).to exist
    end
  end

  context "when the environment names the model as a default" do
    before do
      connection.update_columns(default_chat_model_id: llm_model.id)
      allow(Setting).to receive(:llm_connection).and_return({ "default_chat_model" => "bge-m3" })
    end

    it "refuses and keeps the default" do
      expect(result.errors.symbols_for(:base)).to eq([:configured_from_env])
      expect(connection.reload.default_chat_model_id).to eq(llm_model.id)
    end
  end
end
