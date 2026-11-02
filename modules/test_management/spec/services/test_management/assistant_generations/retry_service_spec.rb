# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::AssistantGenerations::RetryService do
  let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  let(:user) do
    create(:user, member_with_permissions: {
             project => %i[view_test_cases use_test_assistant]
           })
  end
  let(:generation) { create(:tm_assistant_generation, project:, user:, status: "failed") }

  before { ActiveJob::Base.queue_adapter = :test }

  it "requeues a failed generation" do
    expect do
      result = described_class.new(user:, model: generation).call
      expect(result).to be_success
    end.to have_enqueued_job(TestManagement::Assistant::GenerateJob)

    expect(generation.reload.status).to eq("queued")
  end

  it "refuses while the generation is still running" do
    generation.update!(status: "running", updated_at: Time.current)

    result = described_class.new(user:, model: generation).call

    expect(result).to be_failure
    expect(generation.reload.status).to eq("running")
  end
end
