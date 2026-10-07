# frozen_string_literal: true

require "spec_helper"

RSpec.describe Search::SemanticResult do
  describe ".for" do
    let(:user) { create(:user) }
    let(:project) { create(:project, members: { user => create(:project_role, permissions: [:view_work_packages]) }) }
    let!(:wp1) { create(:work_package, project:) }
    let!(:wp2) { create(:work_package, project:) }

    context "when no active binding exists" do
      it "returns no work packages" do
        expect(described_class.for("some query", user)).to be_empty
      end
    end

    context "when a binding exists but is not yet locked (no index)" do
      let(:connection) { create(:llm_connection, :with_models) }
      let!(:binding) do
        create(:llm_feature_binding, llm_connection: connection, feature_key: "semantic_search",
                                     model_id: "bge-m3", dimensions: 3)
      end

      it "returns no work packages" do
        expect(described_class.for("some query", user)).to be_empty
      end
    end

    context "when the binding is locked and embeddings exist" do
      let(:connection) { create(:llm_connection, :with_models) }
      let!(:binding) do
        create(:llm_feature_binding, llm_connection: connection, feature_key: "semantic_search",
                                     model_id: "bge-m3", dimensions: 3,
                                     locked_at: Time.current)
      end
      let(:session_double) { instance_double(Llm::Session) }
      let(:embedding_double) { instance_double(RubyLLM::Embedding, vectors: [0.1, 0.2, 0.3]) }

      before do
        allow(Llm::Session).to receive(:for).with(connection).and_return(session_double)
        allow(session_double).to receive(:embed).and_return(embedding_double)

        create(:work_package_embedding, work_package: wp1, model_id: "bge-m3", dimensions: 3)
        create(:work_package_embedding, work_package: wp2, model_id: "bge-m3", dimensions: 3)
      end

      it "returns work packages visible to the user" do
        result = described_class.for("some query", user)
        expect(result.map(&:id)).to include(wp1.id, wp2.id)
      end

      it "does not return work packages the user cannot see" do
        invisible_wp = create(:work_package)
        create(:work_package_embedding, work_package: invisible_wp, model_id: "bge-m3", dimensions: 3)

        result = described_class.for("some query", user)
        expect(result.map(&:id)).not_to include(invisible_wp.id)
      end

      it "returns no work packages when the LLM call fails" do
        allow(session_double).to receive(:embed).and_raise(Llm::Errors::ConnectionError, "timeout")

        expect(described_class.for("some query", user)).to be_empty
      end
    end
  end
end
