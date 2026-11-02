# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::AssistantGenerations::CancelService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases use_test_assistant]
           })
  end
  let(:generation) { create(:tm_assistant_generation, project:, user:, status: "running") }

  it "cancels a pending generation" do
    result = described_class.new(user:, model: generation).call

    expect(result).to be_success
    expect(generation.reload.status).to eq("cancelled")
  end

  it "is a no-op when the generation is already done" do
    generation.update!(status: "done")

    result = described_class.new(user:, model: generation).call

    expect(result).to be_success
    expect(generation.reload.status).to eq("done")
  end
end
