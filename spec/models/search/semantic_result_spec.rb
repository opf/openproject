# frozen_string_literal: true

require "spec_helper"

RSpec.describe Search::SemanticResult do
  let(:connection) { create(:llm_connection, :with_models) }
  let(:session_double) { instance_double(Llm::Session) }
  let(:embedding_double) { instance_double(RubyLLM::Embedding, vectors: [0.1, 0.2, 0.3]) }

  def create_binding(locked_at: Time.current)
    create(:llm_feature_binding, llm_connection: connection, feature_key: "semantic_search",
                                 model_id: "bge-m3", dimensions: 3, locked_at:)
  end

  describe ".available?" do
    it "is false without a binding" do
      expect(described_class).not_to be_available
    end

    it "is false while the binding is not locked (no index yet)" do
      create_binding(locked_at: nil)

      expect(described_class).not_to be_available
    end

    it "is true once the binding is locked" do
      create_binding

      expect(described_class).to be_available
    end
  end

  describe ".ranked_ids" do
    let!(:closest) { create(:work_package) }
    let!(:close) { create(:work_package) }
    let!(:opposite) { create(:work_package) }

    before do
      allow(Llm::Session).to receive(:for).with(connection).and_return(session_double)
      allow(session_double).to receive(:embed).and_return(embedding_double)

      create(:work_package_embedding, work_package: closest, model_id: "bge-m3", dimensions: 3, embedding: [0.1, 0.2, 0.3])
      create(:work_package_embedding, work_package: close, model_id: "bge-m3", dimensions: 3, embedding: [0.3, 0.2, 0.1])
      create(:work_package_embedding, work_package: opposite, model_id: "bge-m3", dimensions: 3,
                                      embedding: [-0.1, -0.2, -0.3])
    end

    it "returns nothing without a locked binding" do
      create_binding(locked_at: nil)

      expect(described_class.ranked_ids("some query")).to be_empty
    end

    context "with a locked binding" do
      before { create_binding }

      it "returns the ids within the distance cutoff, most similar first" do
        expect(described_class.ranked_ids("some query")).to eq([closest.id, close.id])
      end

      it "embeds the same query only once per request" do
        2.times { described_class.ranked_ids("some query") }

        expect(session_double).to have_received(:embed).once
      end

      it "returns nothing for a blank query" do
        expect(described_class.ranked_ids("")).to be_empty
        expect(session_double).not_to have_received(:embed)
      end

      it "returns nothing when the LLM call fails" do
        allow(session_double).to receive(:embed).and_raise(Llm::Errors::ConnectionError, "timeout")

        expect(described_class.ranked_ids("some query")).to be_empty
      end
    end
  end
end
