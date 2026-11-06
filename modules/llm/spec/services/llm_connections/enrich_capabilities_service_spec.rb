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

RSpec.describe LlmConnections::EnrichCapabilitiesService do
  subject(:service) { described_class.new(connection) }

  let(:connection) { create(:llm_connection) }
  let(:registry) { {} }

  before do
    allow(RubyLLM.models).to receive(:find) do |model_id|
      registry.fetch(model_id) { raise RubyLLM::ModelNotFoundError, model_id }
    end
  end

  def catalogued(id, output: ["text"], capabilities: [], **)
    RubyLLM::Model::Info.new(id:, modalities: { output: }, capabilities:, **)
  end

  def verdict(model_id, capability)
    connection.capability_verdicts.find_by(model_id:, capability: capability.to_s)
  end

  context "with a model the registry catalogues" do
    let!(:llm_model) { create(:llm_model, llm_connection: connection, external_id: "gpt-4o") }
    let(:registry) do
      { "gpt-4o" => catalogued("gpt-4o", capabilities: %w[function_calling vision], name: "GPT-4o", context_window: 128_000) }
    end

    it "records what the registry publishes as metadata" do
      service.call

      expect(verdict("gpt-4o", :vision)).to have_attributes(state: "supported", source: "metadata")
      expect(verdict("gpt-4o", :reasoning)).to have_attributes(state: "unsupported", source: "metadata")
      expect(verdict("gpt-4o", :embeddings)).to have_attributes(state: "unsupported", source: "metadata")
    end

    it "fills in the name and context window the server did not report" do
      service.call

      expect(llm_model.reload.raw_metadata).to include("name" => "GPT-4o", "context_window" => 128_000)
    end

    it "keeps the context window the server reported" do
      llm_model.update!(raw_metadata: { "max_model_len" => 32_768 })

      service.call

      expect(llm_model.reload.raw_metadata).to eq("max_model_len" => 32_768, "name" => "GPT-4o")
    end

    %w[admin probe observed].each do |source|
      it "leaves a verdict from #{source} alone" do
        create(:llm_capability_verdict, llm_connection: connection, model_id: "gpt-4o", capability: "vision",
                                        state: "unsupported", source:)

        service.call

        expect(verdict("gpt-4o", :vision)).to have_attributes(state: "unsupported", source:)
      end
    end

    it "refreshes an earlier metadata verdict" do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "gpt-4o", capability: "vision",
                                      state: "unsupported", source: "metadata", checked_at: 1.day.ago)

      service.call

      expect(verdict("gpt-4o", :vision)).to have_attributes(state: "supported", checked_at: be_within(1.minute).of(Time.current))
    end
  end

  context "when the registry entry has stopped publishing anything about the model" do
    let(:registry) { { "gpt-4o" => catalogued("gpt-4o", output: []) } }

    before { create(:llm_model, llm_connection: connection, external_id: "gpt-4o") }

    it "follows it, so an earlier metadata verdict no longer blocks the model" do
      create(:llm_capability_verdict, llm_connection: connection, model_id: "gpt-4o", capability: "embeddings",
                                      state: "unsupported", source: "metadata")

      service.call

      expect(verdict("gpt-4o", :embeddings)).to have_attributes(state: "unknown", source: "metadata")
    end

    it "records a capability it never published as unknown" do
      service.call

      expect(verdict("gpt-4o", :vision)).to have_attributes(state: "unknown", source: "metadata")
    end
  end

  context "with a model the registry does not know" do
    before { create(:llm_model, llm_connection: connection, external_id: "my-finetune-v3") }

    it "records nothing" do
      expect { service.call }.not_to change(LlmCapabilityVerdict, :count)
    end

    it "still takes the output modality the model card declares" do
      connection.models.first.update!(raw_metadata: { "architecture" => { "output_modalities" => ["embeddings"] } })

      service.call

      expect(verdict("my-finetune-v3", :embeddings)).to have_attributes(state: "supported", source: "metadata")
    end
  end

  context "when the card and the registry disagree" do
    let(:registry) { { "openai/text-embedding-3-small" => catalogued("openai/text-embedding-3-small") } }

    before do
      create(:llm_model, llm_connection: connection, external_id: "openai/text-embedding-3-small",
                         raw_metadata: { "architecture" => { "output_modalities" => ["embeddings"] } })
    end

    it "follows the card" do
      service.call

      expect(verdict("openai/text-embedding-3-small", :embeddings)).to have_attributes(state: "supported")
    end
  end

  context "when the registry lookup raises" do
    before do
      create(:llm_model, llm_connection: connection, external_id: "gpt-4o")
      allow(RubyLLM.models).to receive(:find).and_raise(JSON::ParserError, "broken registry")
    end

    it "skips the model without failing" do
      expect(service.call).to be_success
      expect(connection.capability_verdicts).to be_empty
    end
  end

  context "with a withdrawn model" do
    before { create(:llm_model, :withdrawn, llm_connection: connection, external_id: "gpt-4o") }

    it "does not look it up" do
      service.call

      expect(RubyLLM.models).not_to have_received(:find)
    end
  end
end
