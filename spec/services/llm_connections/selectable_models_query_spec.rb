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

RSpec.describe LlmConnections::SelectableModelsQuery do
  subject(:options) { described_class.new(connection, feature, bound_model_id:).call }

  let(:connection) { create(:llm_connection, :with_models) }
  let(:feature) { OpenProject::Llm::Features[feature_key] }
  let(:feature_key) { :spec_only_vision_feature }
  let(:bound_model_id) { nil }

  before { OpenProject::Llm::Features.register(feature_key, kind: :chat, requires: %i[vision]) }

  after { OpenProject::Llm::Features.all.delete(feature_key) }

  def record_verdict(model_id, state)
    connection.capability_verdicts.create!(model_id:, capability: "vision", state:,
                                           source: "probe", checked_at: Time.current)
  end

  it "offers every chat model while nothing rules one out" do
    expect(options.map(&:model_id)).to contain_exactly("qwen3.6-27b", "bge-m3")
  end

  # Llm::Runtime resolves such a model as :incapable, so picking it could
  # only ever produce a feature that refuses to run.
  it "leaves out a model known to lack a required capability" do
    record_verdict("qwen3.6-27b", "unsupported")

    expect(options.map(&:model_id)).to contain_exactly("bge-m3")
  end

  it "keeps offering a model whose capability could not be determined" do
    record_verdict("qwen3.6-27b", "unknown")

    expect(options.map(&:model_id)).to contain_exactly("qwen3.6-27b", "bge-m3")
  end

  context "when the feature is bound to the ruled out model" do
    let(:bound_model_id) { "qwen3.6-27b" }

    it "keeps it listed, marked as no longer qualifying" do
      record_verdict("qwen3.6-27b", "unsupported")

      expect(options).to contain_exactly(
        described_class::Option.new(model_id: "bge-m3", qualifies: true),
        described_class::Option.new(model_id: "qwen3.6-27b", qualifies: false)
      )
    end
  end
end
