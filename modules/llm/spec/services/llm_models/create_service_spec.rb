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

RSpec.describe LlmModels::CreateService do
  let(:admin) { create(:admin) }
  let(:connection) { create(:llm_connection) }
  let(:params) { { llm_connection: connection, external_id: "bge-m3" } }

  subject(:result) { described_class.new(user: admin).call(**params) }

  it "adds a model entered by hand" do
    expect(result).to be_success
    expect(result.result).to have_attributes(external_id: "bge-m3", manual: true, llm_connection: connection)
    expect(result.result).to be_persisted
  end

  it "asserts no type when none was chosen" do
    expect(connection.capability_verdicts.for_model("bge-m3")).to be_empty
    result
    expect(connection.capability_verdicts.for_model("bge-m3")).to be_empty
  end

  context "with a chosen type and capabilities" do
    let(:params) { super().merge(model_type: "chat", capability_vision: "supported", capability_reasoning: "") }

    it "stores them as the administrator's verdicts" do
      expect(result).to be_success
      expect(connection.capability_verdicts.for_model("bge-m3").pluck(:capability, :state, :source))
        .to contain_exactly(%w[embeddings unsupported admin], %w[vision supported admin])
    end
  end

  context "with a state that is not one" do
    let(:params) { super().merge(model_type: "chat", capability_vision: "maybe") }

    it "persists nothing" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:capability_vision)).to eq([:inclusion])
      expect(connection.models).to be_empty
    end
  end

  context "when the identifier is taken after the uniqueness validation passed" do
    before do
      create(:llm_model, llm_connection: connection, external_id: "bge-m3")
      uniqueness = LlmModel.validators_on(:external_id).grep(ActiveRecord::Validations::UniquenessValidator).first
      allow(uniqueness).to receive(:validate_each)
    end

    it "reports the identifier as taken" do
      expect(result).to be_failure
      expect(result.errors.symbols_for(:external_id)).to eq([:taken])
      expect(connection.models.count).to eq(1)
    end
  end

  context "for a non-admin" do
    let(:admin) { create(:user) }

    it "persists nothing" do
      expect(result).to be_failure
      expect(connection.models).to be_empty
    end
  end
end
