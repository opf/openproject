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

RSpec.describe Llm::Capabilities do
  describe ".published_for" do
    subject(:published) { described_class.published_for("gpt-4o") }

    context "with a model the registry catalogues" do
      before do
        info = RubyLLM::Model::Info.new(id: "gpt-4o", name: "GPT-4o", context_window: 128_000,
                                        modalities: { output: ["text"] }, capabilities: %w[vision])
        allow(RubyLLM.models).to receive(:find).with("gpt-4o").and_return(info)
      end

      it "returns the derived states with the published name and context window" do
        expect(published).to include(display_name: "GPT-4o", context_window: 128_000)
        expect(published[:states]).to include(vision: :supported, reasoning: :unsupported, embeddings: :unsupported)
      end
    end

    context "with a model the registry does not know" do
      before { allow(RubyLLM.models).to receive(:find).and_raise(RubyLLM::ModelNotFoundError) }

      it { is_expected.to be_nil }
    end

    context "when the lookup itself fails" do
      let(:logged) { [] }

      before do
        allow(RubyLLM.models).to receive(:find).and_raise(JSON::ParserError, "broken registry")
        allow(Rails.logger).to receive(:info) { |*args, &block| logged << (block ? block.call : args.first) }
      end

      it "returns nil and logs the failure" do
        expect(published).to be_nil
        expect(logged.join).to include("gpt-4o", "broken registry")
      end
    end
  end

  describe ".label" do
    it "has a translation for every capability" do
      described_class::ALL.each do |capability|
        expect(described_class.label(capability)).not_to include("Translation missing")
      end
    end
  end

  describe ".states_from" do
    subject(:states) { described_class.states_from(info) }

    context "with an embedding entry" do
      let(:info) { RubyLLM::Model::Info.new(id: "embedder", modalities: { output: ["embeddings"] }) }

      it "reports embeddings only" do
        expect(states).to eq(embeddings: :supported)
      end
    end

    context "with a chat entry listing its capabilities" do
      let(:info) do
        RubyLLM::Model::Info.new(id: "chatter", modalities: { output: ["text"] }, capabilities: %w[function_calling vision])
      end

      it "reports the listed ones as supported and the rest as unsupported" do
        expect(states).to eq(embeddings: :unsupported,
                             function_calling: :supported,
                             structured_output: :unsupported,
                             vision: :supported,
                             reasoning: :unsupported)
      end
    end

    context "with a chat entry listing no capability at all" do
      let(:info) { RubyLLM::Model::Info.new(id: "chatter", modalities: { output: ["text"] }) }

      it "leaves the chat capabilities unknown rather than denying them" do
        expect(states).to eq(embeddings: :unsupported,
                             function_calling: :unknown,
                             structured_output: :unknown,
                             vision: :unknown,
                             reasoning: :unknown)
      end
    end

    context "with an entry publishing neither modalities nor capabilities" do
      let(:info) { RubyLLM::Model::Info.new(id: "silent") }

      it "leaves embeddings unknown as well" do
        expect(states).to eq(embeddings: :unknown,
                             function_calling: :unknown,
                             structured_output: :unknown,
                             vision: :unknown,
                             reasoning: :unknown)
      end
    end
  end

  describe ".declared_for" do
    subject(:declared) { described_class.declared_for(raw_metadata) }

    context "with a card declaring embeddings as its output" do
      let(:raw_metadata) { { "architecture" => { "input_modalities" => ["text"], "output_modalities" => ["embeddings"] } } }

      it "reports embeddings as supported" do
        expect(declared).to eq(embeddings: :supported)
      end
    end

    context "with a card declaring another output" do
      let(:raw_metadata) { { "architecture" => { "output_modalities" => %w[text image] } } }

      it "reports embeddings as unsupported" do
        expect(declared).to eq(embeddings: :unsupported)
      end
    end

    context "with a card whose architecture is not an object" do
      let(:raw_metadata) { { "architecture" => "transformer" } }

      it "says nothing rather than raising" do
        expect(declared).to eq({})
      end
    end

    context "with a card declaring nothing" do
      let(:raw_metadata) { { "max_model_len" => 8192 } }

      it "says nothing rather than denying the capability" do
        expect(declared).to eq({})
      end
    end
  end
end
