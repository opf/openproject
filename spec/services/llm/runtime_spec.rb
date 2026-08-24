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

RSpec.describe Llm::Runtime, with_flag: { llm_connection: true } do
  subject(:resolution) { described_class.for(feature_key, override:) }

  let(:feature_key) { :description_assistant }
  let(:override) { nil }

  context "without a connection" do
    it { expect(resolution.status).to eq(:no_connection) }
  end

  context "with a connection that is not enabled" do
    before { create(:llm_connection, :with_models, enabled: false) }

    it { expect(resolution.status).to eq(:no_connection) }
  end

  context "with an enabled connection" do
    let!(:connection) { create(:llm_connection, :with_models, :enabled) }

    it "is unbound until a model is chosen" do
      expect(resolution.status).to eq(:unbound)
      expect(resolution.model_id).to be_nil
    end

    it "falls back to the connection default" do
      connection.update!(default_chat_model_id: "qwen3.6-27b")

      expect(resolution).to be_ready
      expect(resolution.model_id).to eq("qwen3.6-27b")
    end

    it "prefers the feature binding over the connection default" do
      connection.update!(default_chat_model_id: "qwen3.6-27b")
      connection.feature_bindings.create!(feature_key: "description_assistant", model_id: "bge-m3")

      expect(resolution.model_id).to eq("bge-m3")
    end

    context "with a per-item override" do
      let(:override) { "qwen3.6-27b" }

      it "wins over the binding" do
        connection.feature_bindings.create!(feature_key: "description_assistant", model_id: "bge-m3")

        expect(resolution.model_id).to eq("qwen3.6-27b")
      end

      # semantic_search's vectors were written with the bound model; a different
      # one at query time is silently wrong answers, not a preference.
      it "is ignored by a feature that is not overridable" do
        connection.feature_bindings.create!(feature_key: "semantic_search", model_id: "bge-m3")
        connection.capability_verdicts.create!(model_id: "bge-m3", capability: "embeddings",
                                               state: "supported", source: "admin", checked_at: Time.current)

        resolution = described_class.for(:semantic_search, override: "qwen3.6-27b")

        expect(resolution.model_id).to eq("bge-m3")
      end
    end

    # Substituting the default here would silently change the output of a
    # transform an administrator configured deliberately.
    context "when the chosen model is gone from the catalogue" do
      let(:override) { "vanished-model" }

      before { connection.update!(default_chat_model_id: "qwen3.6-27b") }

      it "fails closed rather than falling back" do
        expect(resolution.status).to eq(:model_missing)
        expect(resolution.model_id).to eq("vanished-model")
      end
    end
  end

  describe "capability gating" do
    let(:feature_key) { :semantic_search }
    let!(:connection) { create(:llm_connection, :with_models, :enabled) }

    before { connection.feature_bindings.create!(feature_key: "semantic_search", model_id: "qwen3.6-27b") }

    it "blocks on a definite unsupported verdict" do
      connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "embeddings",
                                             state: "unsupported", source: "probe", checked_at: Time.current)

      expect(resolution.status).to eq(:incapable)
      expect(resolution.missing_capabilities).to eq([:embeddings])
    end

    # Refusing on "we could not tell" would make most self-hosted servers
    # unusable, since the model list carries no capability information at all.
    it "does not block when the verdict is unknown" do
      connection.capability_verdicts.create!(model_id: "qwen3.6-27b", capability: "embeddings",
                                             state: "unknown", source: "probe", checked_at: Time.current)

      expect(resolution).to be_ready
    end

    it "does not block when there is no verdict at all" do
      expect(resolution).to be_ready
    end
  end

  describe "running a request", :llm_server_helpers, :webmock do
    let!(:connection) { create(:llm_connection, :with_models, :enabled, default_chat_model_id: "qwen3.6-27b") }

    it "sends a completion for the resolved model" do
      mock_llm_chat_response("https://example.com/v1", content: "pong")

      expect(resolution.chat(max_retries: 0).ask("ping").content).to eq("pong")
      expect(WebMock).to have_requested(:post, "https://example.com/v1/chat/completions")
        .with(body: hash_including("model" => "qwen3.6-27b"))
    end

    it "refuses when the feature is not ready" do
      connection.update!(enabled: false)

      expect { resolution.chat }.to raise_error(Llm::Errors::NotReady) { |e| expect(e.status).to eq(:no_connection) }
    end

    # Features are resolved by kind, so asking a chat feature to embed means a
    # caller has confused two features.
    it "refuses to embed through a chat feature" do
      expect { resolution.embed("hello") }
        .to raise_error(Llm::Errors::NotReady) { |e| expect(e.status).to eq(:wrong_kind) }
    end

    context "with an embedding feature" do
      let(:feature_key) { :semantic_search }

      before { connection.update!(default_embedding_model_id: "bge-m3") }

      it "requests a vector for the resolved model" do
        mock_llm_embeddings_response("https://example.com/v1", dimensions: 8)

        expect(resolution.embed("hello", max_retries: 0).vectors.length).to eq(8)
      end

      it "refuses to chat through an embedding feature" do
        expect { resolution.chat }
          .to raise_error(Llm::Errors::NotReady) { |e| expect(e.status).to eq(:wrong_kind) }
      end
    end
  end
end
